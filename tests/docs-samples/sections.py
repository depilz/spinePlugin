"""Sections: every API reference page the line shows against the API page section contract (C-1).

Usage: python3 -B tests/docs-samples/sections.py <line> <api_reference dir>
A heading is a column-0 text line over a column-0 line of one repeated punctuation character (its underline), with an
optional line of the same kind above it (its overline). Each page: the first heading is the title, "=" over and under,
both the same length; every other heading is a section ("-" underline) or a sub-section ("~" underline), no overline,
the underline exactly as long as the text, no trailing colon; section names come from SECTIONS, each at most once, in
that order; a sub-section follows a section and never sits under Overview; the header lines are one line block right
after the title, each "| **<Label>:** <value>" with a label from LABELS, each at most once, in that order, and no
"| **" line appears anywhere else. Pages the line hides (docs/_ext/spineline.py LINE_ONLY) are skipped, as in
keys_pages.py. Prints one "<page>: <problem>" line per finding and exits 1 when there is any.
"""
import re
import sys
from pathlib import Path

from keys_pages import pages

SECTIONS = ("Overview", "Syntax", "Parameters", "Return value", "Properties", "Methods", "Aliases", "Example", "Notes",
            "See also")
LABELS = ("Type", "Parent", "Attachment types", "See also")
ADORNMENT = re.compile(r"([!-/:-@\[-`{-~])\1{2,}\s*$")
HEADER = re.compile(r"\| \*\*([^*]+):\*\* ")


def headings(lines):
    """(text line index, text, underline char, underline length, overline or None) for every heading of the page."""
    for i in range(1, len(lines)):
        under, text = ADORNMENT.match(lines[i]), lines[i - 1].rstrip()
        if under and text and not text[0].isspace() and not ADORNMENT.match(text):
            over = lines[i - 2].rstrip() if i >= 2 and ADORNMENT.match(lines[i - 2]) else None
            yield i - 1, text, under.group(1), len(lines[i].rstrip()), over


def in_order(names, allowed, what):
    """Problems of names (line index, name) against allowed: each known, at most once, in allowed's order."""
    last = -1
    for i, name in names:
        if name not in allowed:
            yield f"line {i + 1}: unknown {what} {name!r}"
        elif allowed.index(name) <= last:
            yield f"line {i + 1}: {what} {name!r} out of order or repeated (order: {', '.join(allowed)})"
        else:
            last = allowed.index(name)


def title_problems(title):
    i, text, char, length, over = title
    if char != "=" or over is None or over != "=" * length:
        yield f"line {i + 1}: title {text!r} is not '=' over and under, both the same length"


def heading_problems(found):
    section = None
    for i, text, char, length, over in found:
        if over is not None or char not in "-~":
            yield f"line {i + 1}: heading {text!r} is neither a section ('-' underline) nor a sub-section ('~' underline)"
            continue
        if length != len(text):
            yield f"line {i + 1}: heading {text!r} has an underline of {length}, not {len(text)}"
        if text.endswith(":"):
            yield f"line {i + 1}: heading {text!r} ends with a colon"
        if char == "-":
            section = text
        elif section is None or section == "Overview":
            yield f"line {i + 1}: sub-section {text!r} under {section or 'the title'}"
    yield from in_order([(i, text) for i, text, char, _, over in found if char == "-" and over is None], SECTIONS,
                        "section")


def header_problems(lines, title_end):
    start = title_end + 2 if title_end + 1 < len(lines) and not lines[title_end + 1].strip() else title_end + 1
    end = start
    while end < len(lines) and lines[end].startswith("| "):
        end += 1
    labels = []
    for i in range(start, end):
        match = HEADER.match(lines[i])
        if match:
            labels.append((i, match.group(1)))
        else:
            yield f"line {i + 1}: header line is not '| **<Label>:** <value>'"
    yield from in_order(labels, LABELS, "header label")
    for i, line in enumerate(lines):
        if line.lstrip().startswith("| **") and not start <= i < end:
            yield f"line {i + 1}: header line outside the block under the title"


def page_problems(text):
    lines = text.splitlines()
    found = list(headings(lines))
    if not found:
        return ["no title"]
    return [*title_problems(found[0]), *heading_problems(found[1:]), *header_problems(lines, found[0][0] + 1)]


def main(line, api):
    shown = sorted(pages(api, line))
    problems = [f"{page}.rst: {problem}" for page in shown
                for problem in page_problems((Path(api) / f"{page}.rst").read_text(encoding="utf-8"))]
    print("\n".join(problems) if problems else f"sections: {len(shown)} pages follow C-1")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
