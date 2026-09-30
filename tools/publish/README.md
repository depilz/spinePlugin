# tools/publish

Builds the public history of this repo from private commits, and checks it before and after it is pushed.
`publish.py` is stdlib Python 3 plus `git`. Everything private (the source repo, the map, the deny-file, the hash
list) comes in as an argument and never lives in the repo. Git runs without system or user config and with HOME, TZ
and the locale fixed, so the same arguments give the same SHAs on any machine. `publish.py <command> -h` is the full
contract, including the map and deny-file row formats.

## export

```
tools/publish/publish.py export --map MAP --repo REPO OUT
```

Builds one public commit per `commit` row of MAP, in row order, with `git commit-tree`: the tree of a private source
commit of REPO minus the row's `drop` paths and with its `swap` lines, the map's identity as author and committer,
the row's date and message file, and only the trailers the map declares. Then it writes the map's branches and tags
(annotated tags get the same identity and the date of their commit). OUT must not exist: it becomes a new bare repo
holding exactly the map's refs and their objects, with no link to REPO. It prints each commit's name, sha and tree,
then each ref.

## verify

```
tools/publish/publish.py verify --map MAP --repo REPO --deny-file DENY [--hashes LIST --hash-ref REF] [--pub] TARGET
```

Rebuilds the map and checks TARGET against it. It prints `OK <check>` or one `FAIL <check>: …` line per failure, and
exits 0 when every check passes, 1 when one fails, 2 on bad input.

- `refs`: exactly the map's refs, at the rebuilt objects.
- `trees`: each public tree is its source tree minus the drops, with the swaps.
- `identity`: every commit and tag is the map's identity's, with author, committer and tag dates in agreement.
- `trailers`: each commit carries exactly the map's trailers for it.
- `messages`: no commit or tag message names a note id, a private notes file, a local path, a deny-file text or a
  private sha.
- `deny`: no object, path or content of any reachable tree matches the deny-file.
- `hashes` (with `--hashes`): each file of the sha256sum LIST, read at REF of TARGET, has its listed hash.

TARGET is the export repo, or with `--pub` a fresh `git clone` of the published repo, whose remote branches and tags
then stand for its refs.

## scan

```
tools/publish/publish.py scan --deny-file DENY [--repo REPO] [--drop REGEX]... REV
```

Checks the files of REV's tree (minus the `--drop` paths) against the deny-file: exit 0 when nothing matches, 1 on a
hit. Run it on a commit before it lands on the public line.

## Appending to the public history

Add a `commit` row whose parent is the last public commit, point the branch rows at it, export into a new OUT and
verify it. Earlier rows keep their SHAs, so the push is a fast-forward.

## Tests

`tests/publish/suite.sh` (4.2 line) runs the tool on a synthetic history with invented names, emails and paths:
determinism across paths, TZ, HOME and user config, each check firing on a seeded defect, and `--pub` on a clone.
