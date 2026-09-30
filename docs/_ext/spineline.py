"""Line selection and require-name token for the per-line docs builds.

Shared by docs/conf.py and the docs-samples extractor so both expand samples
the same way. Standard library only: the extractor runs without Sphinx.
"""
import os
import re

# The require/install name in samples and snippets; replaced per line.
TOKEN = "@SPINE_PLUGIN@"

DEFAULT_LINE = "4.2"

LINES = {
    "4.2": {"plugin": "plugin.spine42", "release": "2.0.0", "tag": "spine42"},
    "4.3": {"plugin": "plugin.spine43", "release": "3.0.0", "tag": "spine43"},
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


def base_url(line, environ=os.environ):
    """The URL the build is served from (READTHEDOCS_CANONICAL_URL, no trailing slash); local builds: the line's."""
    url = environ.get("READTHEDOCS_CANONICAL_URL")
    if url:
        return url.rstrip("/")
    return f"https://spineplugin.readthedocs.io/en/{line}"


def connect(app, line):
    """Expand the token in every source file, code blocks included."""
    def on_source_read(app, docname, source):
        source[0] = expand(source[0], line)
    app.connect("source-read", on_source_read)
