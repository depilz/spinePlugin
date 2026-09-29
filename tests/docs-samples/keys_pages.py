"""Keys vs pages: the plugin's public Lua keys against the API reference pages, in one direction per call.

Usage: python3 -B tests/docs-samples/keys_pages.py keys|pages <surface tsv> <api_reference dir>
The surface is tests/api/surface.py's output for the line (owner, kind, key); a public key is one not starting with
"__". Each owner's pages are the <key>.rst files of its OWNER_DIRS directory, so an alias key has its own page like
any other key, except that keys differing only in letter case share one page. keys: every public key has its page,
or, failing an exact-case page, exactly one page of its directory matching it ignoring case. pages: every page names
a public key of its directory's owner, except index.rst and the NOT_KEYS pages, and no page sits in a directory no
owner has. Prints one problem per line and exits 1 when there is any.
"""
import sys
from pathlib import Path

OWNER_DIRS = {
    "module": "spine",
    "SpineObject": "skeleton",
    "SpineBone": "skeleton/bone",
    "SpineIKConstraint": "skeleton/ikConstraint",
    "SpinePhysics": "skeleton/physics",
    "SpineSlot": "skeleton/slot",
    "SpineTrackEntry": "skeleton/trackEntry",
    "SpineFill": "skeleton/fill",
    "SpineEffectData": "skeleton/fill/effect",
    "SpineSkin": "skin",
    "SpineAttachment": "attachment",
}
# pages that document a table the plugin builds, not a key of a registry
NOT_KEYS = {
    "spine/event": "the animation listener's event table",
    "skeleton/injectionEvent": "the inject listener's event table",
}


def public_keys(surface):
    keys = {}
    for row in Path(surface).read_text().splitlines():
        owner, _, key = row.split("\t")
        if not key.startswith("__"):
            keys.setdefault(owner, set()).add(key)
    return keys


def pages(api):
    """Every page as "dir/name" (no .rst), from the directory listing, so letter case is exact on any filesystem (keys
    fall back to a case-insensitive match only when no exact-case page exists)."""
    api = Path(api)
    return {p.relative_to(api).with_suffix("").as_posix() for p in api.rglob("*.rst")}


def keys_without_page(keys, have):
    for owner in sorted(keys):
        if owner not in OWNER_DIRS:
            yield f"{owner}: public keys {' '.join(sorted(keys[owner]))} but no page directory (OWNER_DIRS)"
            continue
        for key in sorted(keys[owner]):
            page = f"{OWNER_DIRS[owner]}/{key}"
            if page not in have and len([p for p in have if p.lower() == page.lower()]) != 1:
                yield f"{owner}.{key}: no page {page}.rst"


def pages_without_key(keys, have):
    owners = {d: o for o, d in OWNER_DIRS.items()}
    for page in sorted(have):
        folder, _, name = page.rpartition("/")
        if name == "index" or page in NOT_KEYS:
            continue
        if folder not in owners:
            yield f"{page}.rst: no owner has the directory {folder or '.'} (OWNER_DIRS)"
        elif name not in keys.get(owners[folder], ()):
            yield f"{page}.rst: {owners[folder]} has no public key {name}"


def main(mode, surface, api):
    check = {"keys": keys_without_page, "pages": pages_without_key}[mode]
    problems = list(check(public_keys(surface), pages(api)))
    print("\n".join(problems) if problems else f"{mode}: none missing")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
