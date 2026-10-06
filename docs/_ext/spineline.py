"""Line selection, require-name token and per-line pages for the per-line docs builds.

Shared by docs/conf.py and the docs-samples extractor so both expand samples
the same way and see the same pages. Standard library only: the extractor runs without Sphinx.
"""
import os
import re

# The require/install name in samples and snippets; replaced per line.
TOKEN = "@SPINE_PLUGIN@"

DEFAULT_LINE = "4.2"

LINES = {
    "4.2": {"plugin": "plugin.spine42", "release": "2.0.1", "tag": "spine42"},
    "4.3": {"plugin": "plugin.spine43", "release": "3.0.1", "tag": "spine43"},
}

# The pages only one line shows: a docname (a page's path under docs/ without .rst) or a directory under docs/ -> its
# line. The other line's build excludes them (conf.py exclude_patterns, toctree entries naming them dropped), and so do
# the docs-samples extraction and the keys vs pages check. A :doc: link to such a page from a page both lines show
# needs its own `.. only::`. Every page not listed here shows on both lines.
LINE_ONLY = {
    "api_reference/attachment/region": "4.3",
    "api_reference/skeleton/createAttachment": "4.3",
    "api_reference/skeleton/slider": "4.3",
    "api_reference/skeleton/sliders": "4.3",
    "api_reference/skeleton/slot/appliedAttachment": "4.3",
    "api_reference/skeleton/trackEntry/additive": "4.3",
    "api_reference/skeleton/trackEntry/holdPrevious": "4.2",
    "api_reference/skeleton/trackEntry/mixInterpolation": "4.3",
}

# The Read the Docs variables that name the version being built: its slug, its git ref name and the ref checked out.
RTD_VARS = ("READTHEDOCS_VERSION", "READTHEDOCS_VERSION_NAME", "READTHEDOCS_GIT_IDENTIFIER")

# A moving ref 4.x, a release tag spine4x-*, a freeze branch release/4.x.* (slug release-4.x.*).
LINE_PATTERNS = (r"4\.([23])$", r"spine4([23])-", r"release[/-]4\.([23])(?:\.|$)")


def line_of(value):
    """The line a Read the Docs identifier names, or None (latest, stable, main, PR numbers, 1.2, ...)."""
    for pattern in LINE_PATTERNS:
        match = re.match(pattern, value or "")
        if match:
            return f"4.{match.group(1)}"
    return None


def select_line(environ):
    """The line the RTD_VARS name, raising when they name two; else SPINE_DOCS_LINE; else the default line."""
    named = {line_of(environ.get(name)) for name in RTD_VARS} - {None}
    if len(named) > 1:
        found = ", ".join(f"{name}={environ.get(name)}" for name in RTD_VARS)
        raise ValueError(f"Read the Docs names two docs lines: {found}")
    if named:
        return named.pop()
    if environ.get("SPINE_DOCS_LINE") in LINES:
        return environ["SPINE_DOCS_LINE"]
    return DEFAULT_LINE


def expand(text, line):
    return text.replace(TOKEN, LINES[line]["plugin"])


def hidden(docname, line, table=LINE_ONLY):
    """True when docname is, or sits under, a table entry of another line."""
    return any(owner != line and (docname == path or docname.startswith(path + "/")) for path, owner in table.items())


def exclude_patterns(line, table=LINE_ONLY):
    """The Sphinx exclude_patterns of the pages the line does not show: each entry as a page and as a directory."""
    return [pattern for path, owner in table.items() if owner != line for pattern in (f"{path}.rst", f"{path}/**")]


def base_url(line, environ=os.environ):
    """The URL the build is served from (READTHEDOCS_CANONICAL_URL, no trailing slash); local builds: the line's."""
    url = environ.get("READTHEDOCS_CANONICAL_URL")
    if url:
        return url.rstrip("/")
    return f"https://spineplugin.readthedocs.io/en/{line}"


def connect(app, line):
    """Expand the token in every source file, code blocks included, and drop the toctree entries naming a page the line
    does not show (Sphinx would warn on each: a reference to an excluded document)."""
    from sphinx.directives.other import TocTree
    from sphinx.util import docname_join
    from sphinx.util.nodes import explicit_title_re

    def target(entry):
        explicit = explicit_title_re.match(entry)
        return explicit.group(2) if explicit else entry

    class LineTocTree(TocTree):
        def parse_content(self, toctree):
            self.content = [e for e in self.content if not hidden(docname_join(self.env.docname, target(e)), line)]
            return super().parse_content(toctree)

    def on_source_read(app, docname, source):
        source[0] = expand(source[0], line)
    app.connect("source-read", on_source_read)
    app.add_directive("toctree", LineTocTree, override=True)
