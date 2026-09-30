"""select_line and base_url of docs/_ext/spineline.py against the Read the Docs environments they must map.

Usage: python3 -B tests/docs-samples/spineline_test.py <docs/_ext dir>
One case per mapping: moving tags, unrenamed and renamed release tags, a contradiction, latest,
stable, PR builds, a dashboard SPINE_DOCS_LINE, freeze branches, look-alikes, 1.2 and the base URLs. Prints one
problem per line and exits 1 when there is any.
"""
import sys

sys.path.insert(0, sys.argv[1])
import spineline


def rtd(version, name=None, identifier=None, **extra):
    """An RTD build environment: slug, git ref name (default the slug) and checked-out ref (default the name)."""
    name = name or version
    return {"READTHEDOCS_VERSION": version, "READTHEDOCS_VERSION_NAME": name,
            "READTHEDOCS_GIT_IDENTIFIER": identifier or name, **extra}


LOOKALIKES = ("4.20", "14.2", "spine421-1.0.0", "release/4.23")

# (case, environ, the line select_line returns)
SELECT = [
    ("default", {}, "4.2"),
    ("local SPINE_DOCS_LINE 4.3", {"SPINE_DOCS_LINE": "4.3"}, "4.3"),
    ("local SPINE_DOCS_LINE 1.2", {"SPINE_DOCS_LINE": "1.2"}, "4.2"),
    ("local SPINE_DOCS_LINE bogus", {"SPINE_DOCS_LINE": "bogus"}, "4.2"),
    ("moving tag 4.2", rtd("4.2", READTHEDOCS_VERSION_TYPE="tag"), "4.2"),
    ("moving tag 4.3", rtd("4.3", READTHEDOCS_VERSION_TYPE="tag"), "4.3"),
    ("unrenamed tag spine42-2.0.0", rtd("spine42-2.0.0"), "4.2"),
    ("unrenamed tag spine43-3.0.0", rtd("spine43-3.0.0"), "4.3"),
    ("patch tag spine43-3.0.1", rtd("spine43-3.0.1"), "4.3"),
    ("renamed slug 4.3 of spine43-3.0.0", rtd("4.3", "spine43-3.0.0"), "4.3"),
    ("latest", rtd("latest", "latest", "main", READTHEDOCS_VERSION_TYPE="branch"), "4.2"),
    ("stable", rtd("stable", "stable", "1.5.0"), "4.2"),
    ("PR build", rtd("17", READTHEDOCS_VERSION_TYPE="external"), "4.2"),
    ("PR build, dashboard SPINE_DOCS_LINE 4.3", rtd("17", SPINE_DOCS_LINE="4.3"), "4.3"),
    ("RTD 4.2 beats dashboard SPINE_DOCS_LINE 4.3", rtd("4.2", SPINE_DOCS_LINE="4.3"), "4.2"),
    ("freeze branch release/4.2.x", rtd("release-4.2.x", "release/4.2.x"), "4.2"),
    ("freeze branch release/4.3.x", rtd("release-4.3.x", "release/4.3.x"), "4.3"),
    ("1.2", rtd("1.2", "release/1.2.x"), "4.2"),
] + [
    # SPINE_DOCS_LINE 4.3 shows the look-alike named no line rather than 4.2 by accident
    (f"look-alike {value}", rtd(value, SPINE_DOCS_LINE="4.3"), "4.3") for value in LOOKALIKES
]

# (case, environ) that select_line refuses
CONTRADICTIONS = [
    ("slug 4.3 of tag spine42-2.0.0", rtd("4.3", "spine42-2.0.0")),
    ("slug 4.2, checked out release/4.3.x", rtd("4.2", "4.2", "release/4.3.x")),
]

# (case, line, environ, base_url)
BASE_URLS = [
    ("canonical 4.2, trailing slash stripped", "4.2",
     {"READTHEDOCS_CANONICAL_URL": "https://spineplugin.readthedocs.io/en/4.2/"},
     "https://spineplugin.readthedocs.io/en/4.2"),
    ("canonical latest on line 4.2", "4.2",
     {"READTHEDOCS_CANONICAL_URL": "https://spineplugin.readthedocs.io/en/latest/"},
     "https://spineplugin.readthedocs.io/en/latest"),
    ("PR preview host passed through", "4.2",
     {"READTHEDOCS_CANONICAL_URL": "https://spineplugin--17.org.readthedocs.build/en/17/"},
     "https://spineplugin--17.org.readthedocs.build/en/17"),
    ("local build, line 4.3", "4.3", {}, "https://spineplugin.readthedocs.io/en/4.3"),
    ("local build, line 4.2", "4.2", {}, "https://spineplugin.readthedocs.io/en/4.2"),
]


def problems():
    for case, environ, want in SELECT:
        try:
            got = spineline.select_line(environ)
        except ValueError as error:
            got = f"ValueError {error}"
        if got != want:
            yield f"select_line {case}: {got}, want {want}"
    for case, environ in CONTRADICTIONS:
        try:
            got = spineline.select_line(environ)
        except ValueError:
            continue
        yield f"select_line {case}: {got}, want ValueError"
    for case, line, environ, want in BASE_URLS:
        got = spineline.base_url(line, environ)
        if got != want:
            yield f"base_url {case}: {got}, want {want}"


found = list(problems())
print("\n".join(found) or f"{len(SELECT) + len(CONTRADICTIONS) + len(BASE_URLS)} cases pass")
sys.exit(1 if found else 0)
