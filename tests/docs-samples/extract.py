"""The Lua samples of the docs as one plugin line's build shows them.

Usage: python3 -B tests/docs-samples/extract.py <docs dir> <line> <out dir>
Reads every <docs dir>/**/*.rst with the line's @SPINE_PLUGIN@ expansion (docs/_ext/spineline.py, the code conf.py
runs), keeps the `.. code-block:: lua` blocks the line's build shows (`.. only::` evaluated with the line's tag), and
writes each sample as <out dir>/<family>/<n>.lua plus one row per sample to <out dir>/samples.tsv:
  family  kind  source  file  reason
kind is run (a headless sample), fragment or simulator, from a marker comment on the nearest non-blank line above
the code-block, at its indent:
  .. fragment: <one-line reason>    not standalone code (a syntax line, a partial snippet); must not run headless
  .. simulator: <one-line reason>   needs the real engine; run in the Simulator, not here
A marker with no reason, or one that is not followed by a Lua code-block, is a row of kind "bad" (its family fails).
The family of a page is the first FAMILIES prefix its path under the docs dir starts with, else "guides".
"""
import re
import sys
from pathlib import Path

FAMILIES = [
    ("api_reference/skeleton/bone/", "bone"),
    ("api_reference/skeleton/ikConstraint/", "ikConstraint"),
    ("api_reference/skeleton/physics/", "physics"),
    ("api_reference/skeleton/slot/", "slot"),
    ("api_reference/skeleton/trackEntry/", "trackEntry"),
    ("api_reference/skeleton/", "skeleton"),
    ("api_reference/skin/", "skin"),
    ("api_reference/attachment/", "attachment"),
    ("api_reference/spine/", "spine"),
    ("quickstart.rst", "quickstart"),
    ("attachments-and-skins.rst", "attachments-and-skins"),
    ("lifecycle.rst", "lifecycle"),
]
GUIDES = "guides"
# the tags of an html build besides the line's own (sphinx adds the format and builder names)
BUILD_TAGS = {"html", "builder_html"}

ONLY = re.compile(r"^(\s*)\.\. only::\s*(.+?)\s*$")
CODE_BLOCK = re.compile(r"^(\s*)\.\. code-block::\s*lua\s*$")
MARKER = re.compile(r"^(\s*)\.\. (fragment|simulator)\b(:?)\s*(.*?)\s*$")


def family(rel):
    return next((name for prefix, name in FAMILIES if rel.startswith(prefix)), GUIDES)


def only_active(expr, tags):
    """Sphinx's `.. only::` expression (tags joined by and/or/not and parentheses) for the given tags."""
    words = re.findall(r"\(|\)|[^\s()]+", expr)
    python = " ".join(w if w in ("and", "or", "not", "(", ")") else str(w in tags) for w in words)
    return bool(eval(python, {"__builtins__": {}}))


def indent(line):
    return len(line) - len(line.lstrip())


def block_body(lines, start, level):
    """The dedented lines of the block starting after lines[start] and indented deeper than level, options dropped."""
    end = start + 1
    while end < len(lines) and (not lines[end].strip() or indent(lines[end]) > level):
        end += 1
    body = lines[start + 1:end]
    while body and (not body[0].strip() or body[0].strip().startswith(":")):
        body = body[1:]
    while body and not body[-1].strip():
        body = body[:-1]
    cut = min((indent(b) for b in body if b.strip()), default=0)
    return [b[cut:] for b in body], end


def samples(rel, text, tags):
    """(kind, source line, code, reason) for every Lua sample of one page the build shows, and every bad marker."""
    lines = text.splitlines()
    only = []           # (indent, active) of the enclosing `.. only::` blocks
    marker = None       # (line number, kind, colon, reason, indent) of a marker waiting for its code-block
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        while only and indent(line) <= only[-1][0]:
            only.pop()
        shown = all(active for _, active in only)
        m = ONLY.match(line)
        if m:
            only.append((len(m.group(1)), only_active(m.group(2), tags)))
        m_code = CODE_BLOCK.match(line)
        if m_code:
            body, end = block_body(lines, i, len(m_code.group(1)))
            kind, reason = "run", ""
            if marker and marker[4] == len(m_code.group(1)):
                kind, reason = marker[1], marker[3]
                if not (marker[2] and reason):
                    kind, reason = "bad", f"{marker[1]} marker at line {marker[0]} has no one-line reason"
                marker = None
            if shown:
                yield kind, i + 1, "\n".join(body) + "\n", reason
            i = end
            continue
        if marker:
            if shown:
                yield "bad", marker[0], "", f"{marker[1]} marker at line {marker[0]} is not followed by a Lua code-block"
            marker = None
        m = MARKER.match(line)
        if m:
            marker = (i + 1, m.group(2), m.group(3), m.group(4), len(m.group(1)))
        i += 1
    if marker:
        yield "bad", marker[0], "", f"{marker[1]} marker at line {marker[0]} is not followed by a Lua code-block"


def main(docs, line, out):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "docs" / "_ext"))
    import spineline

    docs, out = Path(docs), Path(out)
    tags = BUILD_TAGS | {spineline.LINES[line]["tag"]}
    rows, count = [], {}
    for page in sorted(docs.rglob("*.rst")):
        rel = page.relative_to(docs).as_posix()
        fam = family(rel)
        for kind, number, code, reason in samples(rel, spineline.expand(page.read_text(), line), tags):
            count[fam] = count.get(fam, 0) + 1
            file = out / fam / f"{count[fam]:03d}.lua"
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_text(code)
            rows.append("\t".join([fam, kind, f"{rel}:{number}", str(file), reason]))
    (out / "samples.tsv").write_text("".join(r + "\n" for r in rows))


if __name__ == "__main__":
    main(*sys.argv[1:])
