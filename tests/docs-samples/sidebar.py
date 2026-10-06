"""Sidebar: the toctrees of the API reference pages the line shows, which make the docs sidebar.

Usage: python3 -B tests/docs-samples/sidebar.py <line> <api_reference dir>
A toctree entry is "<label> <target>" or a bare "<target>" (the sidebar then shows the target page's title), the target
relative to its page. Every entry outside the root index.rst has the label short_label gives the target's title (the
root index lists the objects by their titles); no target is listed by two entries across the toctrees; no two entries
of one toctree share a label. Pages the line hides, and entries naming one, are skipped (docs/_ext/spineline.py
LINE_ONLY), as the line's docs build drops them. Prints one "<page>: <problem>" line per finding and exits 1 when
there is any.
"""
import posixpath
import re
import sys
from pathlib import Path

from keys_pages import API, pages
from sections import headings
import spineline  # on sys.path through keys_pages

ROOT = "index"
# a title's object path (dotted words up to its last "." or ":"), the name after it, and "(" when it is a call; a title
# with no object path keeps its whole title
SHORT = re.compile(r"[\w.]+[.:](\w+)(\()?")
# an entry with an explicit title, as Sphinx reads it (sphinx.util.nodes.explicit_title_re)
EXPLICIT = re.compile(r"(.+?)\s*<([^<]*?)>$")


def short_label(title):
    """The title's first name without its object path, "()" for a call: "skeleton:setAnimation()" -> "setAnimation()",
    "skeleton.fill.effect and tint black" -> "effect"; a title with no object path keeps its whole title: "spineEvent"
    -> "spineEvent"."""
    match = SHORT.match(title)
    if match:
        return match.group(1) + ("()" if match.group(2) else "")
    return title


def page_title(path):
    found = next(headings(path.read_text(encoding="utf-8").splitlines()), None)
    return found[1] if found else None


def toctrees(lines):
    """Each toctree of the page as its [(line index, entry text)]: the lines indented under the directive that are
    neither blank nor an option."""
    for start, directive in enumerate(lines):
        if directive.strip() != ".. toctree::":
            continue
        indent = len(directive) - len(directive.lstrip())
        body = []
        for i in range(start + 1, len(lines)):
            text = lines[i].strip()
            if text and len(lines[i]) - len(lines[i].lstrip()) <= indent:
                break
            if text and not text.startswith(":"):
                body.append((i, text))
        yield body


def toctree_problems(page, toctree, titles, listed, line):
    """The toctree's problems; listed maps each target already seen to where ("<page>.rst:<line>")."""
    labels = {}
    for i, text in toctree:
        explicit = EXPLICIT.match(text)
        label, target = explicit.groups() if explicit else (None, text)
        docname = posixpath.normpath(posixpath.join(posixpath.dirname(page), target))
        if spineline.hidden(f"{API}/{docname}", line):
            continue
        if not titles.get(docname):
            yield f"line {i + 1}: no titled page {docname}.rst"
            continue
        short = short_label(titles[docname])
        if page != ROOT and label != short:
            yield f"line {i + 1}: entry {text!r} is not '{short} <{target}>'"
        if docname in listed:
            yield f"line {i + 1}: {docname} is already listed at {listed[docname]}"
        listed.setdefault(docname, f"{page}.rst:{i + 1}")
        shown = label or titles[docname]
        if shown in labels:
            yield f"line {i + 1}: label {shown!r} is also on line {labels[shown] + 1} of this toctree"
        labels.setdefault(shown, i)


def main(line, api):
    shown = sorted(pages(api, line))
    titles = {page: page_title(Path(api) / f"{page}.rst") for page in shown}
    listed = {}
    problems = [f"{page}.rst: {problem}" for page in shown
                for toctree in toctrees((Path(api) / f"{page}.rst").read_text(encoding="utf-8").splitlines())
                for problem in toctree_problems(page, toctree, titles, listed, line)]
    print("\n".join(problems) if problems else f"sidebar: {len(listed)} pages listed once, each by its short label")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
