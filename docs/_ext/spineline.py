"""Line selection and require-name token for the per-line docs builds.

Shared by docs/conf.py and the docs-samples extractor so both expand samples
the same way. Standard library only: the extractor runs without Sphinx.
"""

# The require/install name in samples and snippets; replaced per line.
TOKEN = "@SPINE_PLUGIN@"

DEFAULT_LINE = "4.2"

LINES = {
    "4.2": {"plugin": "plugin.spine42", "release": "2.0.0", "tag": "spine42"},
    "4.3": {"plugin": "plugin.spine43", "release": "3.0.0", "tag": "spine43"},
}


def select_line(environ):
    """READTHEDOCS_VERSION, else SPINE_DOCS_LINE; anything else is the default line."""
    for name in ("READTHEDOCS_VERSION", "SPINE_DOCS_LINE"):
        if environ.get(name) in LINES:
            return environ[name]
    return DEFAULT_LINE


def expand(text, line):
    return text.replace(TOKEN, LINES[line]["plugin"])


def base_url(line):
    return f"https://spineplugin.readthedocs.io/en/{line}"


def connect(app, line):
    """Expand the token in every source file, code blocks included."""
    def on_source_read(app, docname, source):
        source[0] = expand(source[0], line)
    app.connect("source-read", on_source_read)
