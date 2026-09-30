#!/usr/bin/env python3
"""Builds a public git history from private commits, and checks one: publish.py export|verify|scan (see -h).
Everything private (the source repo, the map, the deny-file, the hash list) comes in as an argument. git runs without
system or user config and with HOME, TZ and the locale fixed, so the same arguments give the same SHAs on any machine.
"""
import argparse
import hashlib
import os
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

GIT_OPTIONS = ["-c", "commit.gpgSign=false", "-c", "tag.gpgSign=false", "-c", f"core.hooksPath={os.devnull}"]
MAP_ROWS = {"identity": 2, "commit": 5, "drop": 2, "swap": 4, "trailer": 2, "tag": 3, "ref": 2}
DENY_ROWS = {"text": 1, "path": 1, "object": 1, "sha": 1}
# message leaks: a note id (a capital letter, a number, maybe a or b), a private notes name, a local path
LEAK_PATTERNS = [rb"\b[CDFIKNOARQL][0-9]+[ab]?\b", rb"rocks", rb"PROMPT", rb"STATUS", rb"FACTS", rb"/Users/",
                 rb"/Volumes/"]
# a leak hit inside one of these is none: a compiler optimisation flag
LEAK_ALLOW = re.compile(rb"-O[0-9]\b")
SHA = re.compile(r"[0-9a-f]{40}")
PREFIX = re.compile(r"[0-9a-f]{7,40}")
DATE = re.compile(r"[0-9]+ [+-][0-9]{4}")
HASH_ROW = re.compile(r"([0-9a-f]{64})  (\S.*)")

MAP_HELP = """tab-separated rows, # for comments; paths are relative to the map's directory:
  identity NAME EMAIL                          author, committer and tagger of every public object
  commit NAME SOURCE PARENT DATE MESSAGE       one public commit, built in row order: the tree of SOURCE (a full
                                               private sha), PARENT (an earlier NAME, or - for a root), DATE as
                                               '<epoch> <+hhmm>' for author, committer and its tags, MESSAGE a file
  drop NAME REGEX                              remove every file of NAME's tree whose path REGEX matches (one at least)
  swap NAME PATH OLD NEW                       in NAME's tree, PATH's one line OLD becomes NEW
  trailer NAME LINE                            a trailer line for NAME's message, the only one it may carry
  tag REF NAME MESSAGE                         an annotated tag refs/tags/... on NAME
  ref REF NAME                                 a ref (a branch or a lightweight tag) on NAME"""
DENY_HELP = """tab-separated rows, # for comments:
  text REGEX     no object (verify) or file (scan) content matches REGEX, nor any message
  path REGEX     no path of any tree matches REGEX
  object PREFIX  no object id starts with PREFIX, nor does any message name it
  sha PREFIX     no message names PREFIX (a private commit)"""


class Fail(Exception):
    """bad input or a git error: exit 2"""


WORK = Path()  # the run's temporary dir, HOME of every git call


@dataclass
class Commit:
    name: str
    source: str
    parent: str  # "" for a root commit
    date: str
    message: Path
    drops: list = field(default_factory=list)
    swaps: list = field(default_factory=list)  # (path, old line, new line)
    trailers: list = field(default_factory=list)


@dataclass
class Map:
    name: str = ""
    email: str = ""
    commits: dict = field(default_factory=dict)  # name -> Commit, in build order
    refs: dict = field(default_factory=dict)  # ref -> (commit name, tag message file or None)


def git_command(repo, args, env=None):
    """argv and environment of git args in repo (None: the current dir), with no user or system config"""
    clean = {k: v for k, v in os.environ.items() if not k.startswith("GIT_") and k != "XDG_CONFIG_HOME"}
    clean.update(GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull, HOME=str(WORK), TZ="UTC", LC_ALL="C")
    clean.update(env or {})
    where = ["-C", str(repo)] if repo else []
    return ["git", *GIT_OPTIONS, *where, *args], clean


def git(repo, *args, stdin=None, env=None):
    argv, env = git_command(repo, args, env)
    r = subprocess.run(argv, input=stdin, env=env, capture_output=True)
    if r.returncode:
        raise Fail(f"git {' '.join(args)}: {r.stderr.decode(errors='replace').strip()}")
    return r.stdout


def git_line(repo, *args, **kw):
    return git(repo, *args, **kw).decode().strip()


def objects(repo, ids=None):
    """(type, id, content) of the objects ids names in repo; None: every object, reachable or not"""
    args = ["cat-file", "--batch"] if ids is not None else ["cat-file", "--batch-all-objects", "--batch"]
    argv, env = git_command(repo, args)
    ids_file = WORK / "ids"
    ids_file.write_text("".join(f"{i}\n" for i in ids or []))
    with ids_file.open() as stdin, subprocess.Popen(argv, env=env, stdin=stdin, stdout=subprocess.PIPE) as p:
        while header := p.stdout.readline():
            sha, kind, size = header.decode().split()
            yield kind, sha, p.stdout.read(int(size))
            p.stdout.read(1)
    if p.returncode:
        raise Fail(f"git {' '.join(args)} failed in {repo}")


def compile_path(pattern, where):
    try:
        return re.compile(pattern)
    except re.error as e:
        raise Fail(f"{where}: {e}")


def read_text(path):
    try:
        return Path(path).read_text()
    except OSError as e:
        raise Fail(f"{path}: {e.strerror}")


def read_rows(path, kinds):
    """(where, kind, fields) of each row of a tab-separated file"""
    for no, line in enumerate(read_text(path).splitlines(), 1):
        if not line or line.startswith("#"):
            continue
        kind, *fields = line.split("\t")
        if kinds.get(kind) != len(fields) or not all(fields):
            raise Fail(f"{path}:{no}: not a row of the form -h shows")
        yield f"{path}:{no}", kind, fields


def add_commit(m, where, fields, base):
    name, source, parent, date, message = fields
    if name in m.commits or not SHA.fullmatch(source) or not DATE.fullmatch(date):
        raise Fail(f"{where}: a commit needs a new name, a full source sha and '<epoch> <+hhmm>'")
    if parent != "-" and parent not in m.commits:
        raise Fail(f"{where}: parent {parent} is not a commit above")
    m.commits[name] = Commit(name, source, "" if parent == "-" else parent, date, base / message)


def add_ref(m, where, kind, fields, base):
    ref, name = fields[:2]
    if ref in m.refs or not ref.startswith("refs/tags/" if kind == "tag" else "refs/"):
        raise Fail(f"{where}: {ref} is repeated or not a {'refs/tags/' if kind == 'tag' else 'refs/'} name")
    if name not in m.commits:
        raise Fail(f"{where}: {name} is not a commit above")
    m.refs[ref] = (name, base / fields[2] if kind == "tag" else None)


def read_map(path):
    m, base = Map(), Path(path).parent
    for where, kind, f in read_rows(path, MAP_ROWS):
        if kind == "identity":
            m.name, m.email = f
        elif kind == "commit":
            add_commit(m, where, f, base)
        elif kind in ("tag", "ref"):
            add_ref(m, where, kind, f, base)
        elif f[0] not in m.commits:
            raise Fail(f"{where}: {f[0]} is not a commit above")
        elif kind == "drop":
            m.commits[f[0]].drops.append(compile_path(f[1], where))
        elif kind == "swap":
            m.commits[f[0]].swaps.append(tuple(f[1:]))
        else:
            m.commits[f[0]].trailers.append(f[1])
    if not (m.name and m.refs):
        raise Fail(f"{path}: needs an identity, a commit and a ref")
    return m


def read_deny(path):
    deny = {kind: [] for kind in DENY_ROWS}
    for where, kind, (value,) in read_rows(path, DENY_ROWS):
        if kind in ("object", "sha") and not PREFIX.fullmatch(value):
            raise Fail(f"{where}: {kind} wants 7 to 40 lowercase hex digits")
        if kind == "text":
            value = re.compile(compile_path(value, where).pattern.encode())
        elif kind == "path":
            value = compile_path(value, where)
        deny[kind].append(value)
    return deny


def read_hashes(path):
    """(sha256, path) of each line of a sha256sum list"""
    rows = []
    for no, line in enumerate(read_text(path).splitlines(), 1):
        hit = HASH_ROW.fullmatch(line)
        if not hit:
            raise Fail(f"{path}:{no}: not '<sha256>  <path>'")
        rows.append(hit.groups())
    if not rows:
        raise Fail(f"{path}: no hash")
    return rows


def files(repo, tree):
    """path -> (mode, id) of every file of a tree"""
    out = {}
    for entry in git(repo, "ls-tree", "-r", "-z", "--full-tree", tree).split(b"\0")[:-1]:
        meta, path = entry.split(b"\t", 1)
        mode, _, sha = meta.decode().split()
        out[path.decode("utf-8", "surrogateescape")] = (mode, sha)
    return out


def dropped(c, paths):
    """the paths c's drops remove"""
    out = set()
    for rx in c.drops:
        hit = {p for p in paths if rx.search(p)}
        if not hit:
            raise Fail(f"{c.name}: drop {rx.pattern} matches no path")
        out |= hit
    return out


def swapped(repo, c, tree, swap):
    """(mode, content) of c's file after one of its swaps"""
    path, old, new = swap
    if path not in tree:
        raise Fail(f"{c.name}: swap of a missing file {path}")
    mode, sha = tree[path]
    lines = git(repo, "cat-file", "blob", sha).split(b"\n")
    at = [i for i, line in enumerate(lines) if line == old.encode()]
    if len(at) != 1:
        raise Fail(f"{c.name}: {len(at)} lines of {path} are {old!r}, a swap needs one")
    lines[at[0]] = new.encode()
    return mode, b"\n".join(lines)


def public_tree(repo, c):
    """writes c's source tree minus its drops, with its swaps, to repo; its id"""
    source = f"{c.source}^{{tree}}"
    tree = files(repo, source)
    env = {"GIT_INDEX_FILE": str(WORK / "index")}
    entries = [f"0 {'0' * 40}\t{p}" for p in sorted(dropped(c, tree))]  # mode 0 removes the path
    for swap in c.swaps:
        mode, content = swapped(repo, c, tree, swap)
        entries.append(f"{mode} {git_line(repo, 'hash-object', '-w', '--stdin', stdin=content)}\t{swap[0]}")
    git(repo, "read-tree", source, env=env)
    git(repo, "update-index", "-z", "--index-info", stdin="".join(e + "\0" for e in entries).encode(
        "utf-8", "surrogateescape"), env=env)
    return git_line(repo, "write-tree", env=env)


def message(path, trailers=()):
    """a message file without trailing whitespace, then the trailers as its last paragraph"""
    text = read_text(path).rstrip()
    if not text:
        raise Fail(f"{path}: empty message")
    return ("\n\n".join([text, "\n".join(trailers)]) if trailers else text).encode() + b"\n"


def borrow(repo, *sources):
    """lets repo read the objects of the source repos"""
    dirs = [git_line(s, "rev-parse", "--path-format=absolute", "--git-common-dir") for s in sources]
    (Path(repo) / "objects/info/alternates").write_text("".join(f"{d}/objects\n" for d in dirs))


def build(m, source, repo):
    """writes m's commits and refs into a new bare repo that reads source's objects; name -> sha, ref -> object"""
    git(None, "init", "-q", "--bare", str(repo))
    borrow(repo, source)
    shas = {}
    for c in m.commits.values():
        if git(repo, "cat-file", "-t", c.source) != b"commit\n":
            raise Fail(f"{c.name}: {c.source} is not a commit of {source}")
        who = {f"GIT_{role}_{k}": v for role in ("AUTHOR", "COMMITTER")
               for k, v in (("NAME", m.name), ("EMAIL", m.email), ("DATE", c.date))}
        parent = ["-p", shas[c.parent]] if c.parent else []
        shas[c.name] = git_line(repo, "commit-tree", public_tree(repo, c), *parent,
                                stdin=message(c.message, c.trailers), env=who)
    refs = {}
    for ref, (name, tag_message) in m.refs.items():
        refs[ref] = tag(repo, m, ref, shas[name], m.commits[name].date, tag_message) if tag_message else shas[name]
        git(repo, "update-ref", ref, refs[ref])
    return shas, refs


def tag(repo, m, ref, commit, date, message_file):
    """an annotated tag object on commit"""
    head = f"object {commit}\ntype commit\ntag {ref[len('refs/tags/'):]}\ntagger {m.name} <{m.email}> {date}\n\n"
    return git_line(repo, "mktag", stdin=head.encode() + message(message_file))


def export(a):
    m = read_map(a.map)
    if a.out.exists():
        raise Fail(f"{a.out} exists; export writes a new repo")
    scratch = WORK / "scratch.git"
    shas, refs = build(m, a.repo, scratch)
    heads = [r[len("refs/heads/"):] for r in m.refs if r.startswith("refs/heads/")]
    git(None, "init", "-q", "--bare", "-b", (heads or ["main"])[0], str(a.out))
    git(a.out, "fetch", "-q", "--no-tags", "--no-write-fetch-head", str(scratch), *(f"{r}:{r}" for r in refs))
    for name, sha in shas.items():
        print(f"commit\t{name}\t{sha}\t{git_line(a.out, 'rev-parse', sha + '^{tree}')}")
    for ref, obj in refs.items():
        print(f"ref\t{ref}\t{obj}")
    return 0


def target_refs(repo, pub):
    """ref -> object of repo; with pub, a clone's view of its origin: its remote branches and its tags"""
    refs = {}
    for line in git(repo, "for-each-ref", "--format=%(objectname) %(refname)").decode().splitlines():
        obj, ref = line.split(" ", 1)
        if not pub:
            refs[ref] = obj
        elif ref.startswith("refs/remotes/origin/") and ref != "refs/remotes/origin/HEAD":
            refs["refs/heads/" + ref[len("refs/remotes/origin/"):]] = obj
        elif ref.startswith("refs/tags/"):
            refs[ref] = obj
    return refs


def check_refs(refs, expected):
    failures = [f"missing {r}" for r in sorted(expected.keys() - refs.keys())]
    failures += [f"extra {r}" for r in sorted(refs.keys() - expected.keys())]
    return failures + [f"{r} is {refs[r]}, the map builds {expected[r]}"
                       for r in sorted(refs.keys() & expected.keys()) if refs[r] != expected[r]]


def walk(repo, m, refs):
    """public sha -> map commit name, for the commits the map's refs reach through the map's parents; failures"""
    names, failures = {}, []
    todo = [(git_line(repo, "rev-parse", refs[r] + "^{commit}"), name) for r, (name, _) in m.refs.items() if r in refs]
    while todo:
        sha, name = todo.pop()
        if sha in names:
            failures += [f"{sha} is both {names[sha]} and {name}"] if names[sha] != name else []
            continue
        names[sha] = name
        parents, parent = git_line(repo, "log", "-1", "--format=%P", sha).split(), m.commits[name].parent
        if len(parents) != (1 if parent else 0):
            failures.append(f"{sha} ({name}) has {len(parents)} parents, the map {1 if parent else 0}")
        elif parent:
            todo.append((parents[0], parent))
    return names, failures


def check_trees(repo, m, names):
    """each public tree is its source tree minus the map's drops, with its swaps; repo reads both sides"""
    failures = []
    for sha, name in sorted(names.items()):
        c = m.commits[name]
        private, public = files(repo, c.source + "^{tree}"), files(repo, sha + "^{tree}")
        gone = dropped(c, private)
        want = {p: entry for p, entry in private.items() if p not in gone}
        for swap in c.swaps:
            mode, content = swapped(repo, c, private, swap)
            want[swap[0]] = (mode, git_line(repo, "hash-object", "--stdin", stdin=content))
        failures += [f"{name} {sha}: {p} is {public.get(p, 'absent')}, the map {want.get(p, 'absent')}"
                     for p in sorted(want.keys() | public.keys()) if want.get(p) != public.get(p)]
    return failures


def check_identity(repo, m):
    """every commit and tag is the map's identity's, a commit's author and committer dates and a tag's date agree"""
    who, failures = f"{m.name} <{m.email}>", []
    log = git(repo, "log", "--all", "--date=raw", "--format=%H%x09%an <%ae>%x09%cn <%ce>%x09%ad%x09%cd").decode()
    for sha, author, committer, adate, cdate in (line.split("\t") for line in log.splitlines()):
        if (author, committer) != (who, who) or adate != cdate:
            failures.append(f"commit {sha}: author {author} {adate}, committer {committer} {cdate}")
    fmt = "%(objecttype)%09%(refname)%09%(taggername) %(taggeremail)%09%(taggerdate:raw)%09%(*committerdate:raw)"
    for line in git(repo, "for-each-ref", f"--format={fmt}").decode().splitlines():
        kind, ref, tagger, tdate, cdate = line.split("\t")
        if kind == "tag" and (tagger != who or tdate != cdate):
            failures.append(f"tag {ref}: tagger {tagger} {tdate}, its commit {cdate}")
    return failures


def check_trailers(repo, m, names):
    """a commit carries exactly the map's trailers for it, and one off the map none"""
    failures = []
    for sha in git_line(repo, "rev-list", "--all").split():
        want = m.commits[names[sha]].trailers if sha in names else []
        body = git(repo, "log", "-1", "--format=%B", sha)
        got = git(repo, "interpret-trailers", "--parse", stdin=body).decode().splitlines()
        if got != want:
            failures.append(f"{sha}: trailers {got}, the map {want}")
    return failures


def messages(repo):
    """(label, message) of every commit and every tag object"""
    for record in git(repo, "log", "--all", "-z", "--format=commit %H%n%B").split(b"\0")[:-1]:
        label, _, body = record.partition(b"\n")
        yield label.decode(), body
    fmt = "%(objecttype) %(refname)%0a%(contents)%00"
    for record in git(repo, "for-each-ref", f"--format={fmt}").split(b"\0")[:-1]:
        label, _, body = record.lstrip(b"\n").partition(b"\n")
        if label.startswith(b"tag "):
            yield label.decode(), body


def check_messages(repo, deny):
    patterns = [re.compile(p) for p in LEAK_PATTERNS] + deny["text"]
    patterns += [re.compile(rb"\b" + p.encode()) for p in deny["sha"] + deny["object"]]
    failures = []
    for label, body in messages(repo):
        allowed = [a.span() for a in LEAK_ALLOW.finditer(body)]
        failures += [f"{label}: {rx.pattern.decode()} matches {hit.group().decode(errors='replace')!r}"
                     for rx in patterns for hit in rx.finditer(body)
                     if not any(s <= hit.start() and hit.end() <= e for s, e in allowed)]
    return failures


def deny_hits(repo, deny, paths, ids=None):
    """deny-file hits: a path pattern in paths, an id prefix or a text pattern in the objects ids (None: all of repo)"""
    failures = sorted({f"path {rx.pattern} matches {p}" for p in paths for rx in deny["path"] if rx.search(p)})
    for kind, sha, content in objects(repo, ids):
        failures += [f"object {sha} ({kind}) starts with {p}" for p in deny["object"] if sha.startswith(p)]
        failures += [f"text {rx.pattern.decode()} in {kind} {sha}" for rx in deny["text"] if rx.search(content)]
    return failures


def history_paths(repo):
    """every path of every tree of every commit"""
    trees = set(git_line(repo, "log", "--all", "--format=%T").split())
    return {p.decode("utf-8", "surrogateescape") for t in trees
            for p in git(repo, "ls-tree", "-r", "-t", "-z", "--name-only", t).split(b"\0")[:-1]}


def check_hashes(repo, ref, rows):
    failures = []
    for digest, path in rows:
        try:
            got = hashlib.sha256(git(repo, "cat-file", "blob", f"{ref}:{path}")).hexdigest()
        except Fail:
            got = "absent"
        if got != digest:
            failures.append(f"{ref}:{path} is {got}, the list {digest}")
    return failures


def verify(a):
    if bool(a.hashes) != bool(a.hash_ref):
        raise Fail("--hashes and --hash-ref go together")
    m, deny = read_map(a.map), read_deny(a.deny_file)
    hashes = read_hashes(a.hashes) if a.hashes else []
    rebuild = WORK / "rebuild.git"
    _, expected = build(m, a.repo, rebuild)
    borrow(rebuild, a.repo, a.target)
    refs = target_refs(a.target, a.pub)
    names, chain_failures = walk(a.target, m, refs)
    results = {
        "refs": check_refs(refs, expected),
        "trees": chain_failures + check_trees(rebuild, m, names),
        "identity": check_identity(a.target, m),
        "trailers": check_trailers(a.target, m, names),
        "messages": check_messages(a.target, deny),
        "deny": deny_hits(a.target, deny, history_paths(a.target)),
    }
    if hashes:
        results["hashes"] = check_hashes(a.target, a.hash_ref, hashes)
    return report(results)


def scan(a):
    deny = read_deny(a.deny_file)
    drops = [compile_path(d, "--drop") for d in a.drop]
    tree = {p: e for p, e in files(a.repo, a.rev + "^{tree}").items() if not any(rx.search(p) for rx in drops)}
    return report({"deny": deny_hits(a.repo, deny, tree, [sha for _, sha in tree.values()])})


def report(results):
    for check, failures in results.items():
        print(f"OK {check}" if not failures else "\n".join(f"FAIL {check}: {f}" for f in failures))
    return 1 if any(results.values()) else 0


def parser():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(required=True, metavar="export|verify|scan")
    path = lambda s: Path(s).resolve()
    e = sub.add_parser("export", formatter_class=argparse.RawDescriptionHelpFormatter, epilog=MAP_HELP,
                       help="build the map's commits and refs into a new bare repo OUT; prints each commit's name, "
                            "sha and tree and each ref")
    v = sub.add_parser("verify", formatter_class=argparse.RawDescriptionHelpFormatter, epilog=DENY_HELP,
                       help="check TARGET against the map, the deny-file and the hash list; prints OK|FAIL per "
                            "check, exit 0 = every check passed, 1 = a check failed, 2 = bad input")
    s = sub.add_parser("scan", formatter_class=argparse.RawDescriptionHelpFormatter, epilog=DENY_HELP,
                       help="check the files of one tree against the deny-file; exit 0 = no hit, 1 = a hit")
    for q in (e, v):
        q.add_argument("--map", type=path, required=True, help="the map file (export -h shows its rows)")
        q.add_argument("--repo", type=path, required=True, help="the private repo holding the source commits")
    e.add_argument("out", type=path, metavar="OUT")
    for q in (v, s):
        q.add_argument("--deny-file", type=path, required=True, help="the deny-file (rows below)")
    v.add_argument("--hashes", type=path, help="a sha256sum list of files every one of which --hash-ref must hold")
    v.add_argument("--hash-ref", help="the ref of TARGET the --hashes files are read at")
    v.add_argument("--pub", action="store_true",
                   help="TARGET is a clone of the published repo: its origin's branches and its tags are the refs")
    v.add_argument("target", type=path, metavar="TARGET")
    s.add_argument("--repo", type=path, default=Path.cwd(), help="the repo holding REV (default: the current dir)")
    s.add_argument("--drop", action="append", default=[], metavar="REGEX", help="leave out the files it matches")
    s.add_argument("rev", metavar="REV")
    e.set_defaults(run=export)
    v.set_defaults(run=verify)
    s.set_defaults(run=scan)
    return p


def main():
    global WORK
    a = parser().parse_args()
    with tempfile.TemporaryDirectory(prefix="publish.") as tmp:
        WORK = Path(tmp)
        try:
            return a.run(a)
        except Fail as e:
            print(f"publish.py: {e}", file=sys.stderr)
            return 2


if __name__ == "__main__":
    sys.exit(main())
