#!/usr/bin/env python3
"""Writes the worldspace fixture assets/<line>/hitboxes.json for every line; --check compares instead and exits 1
on a difference. The line files differ only in the "spine" version string. Loaded with spineboy/spineboy.atlas
(bounding boxes need no region)."""
import json
import pathlib
import sys

VERSIONS = {"4.2": "4.2.22", "4.3": "4.3.75-beta"}
NAME = "hitboxes.json"


def square(x0, y0, x1, y1):
    return {"type": "boundingbox", "vertexCount": 4, "vertices": [x0, y0, x1, y0, x1, y1, x0, y1]}


def fixture(version):
    return {
        "skeleton": {"spine": version},
        "bones": [
            {"name": "root"},
            {"name": "base", "parent": "root"},
            {"name": "skinbone", "parent": "root", "x": 200, "skin": True},
            {"name": "chain1", "parent": "root", "x": 50, "y": 20, "rotation": 30, "scaleX": 1.5, "scaleY": 0.75,
             "shearX": 10, "shearY": -5},
            {"name": "chain2", "parent": "chain1", "x": 40, "rotation": -20, "scaleX": 0.8, "scaleY": 1.25,
             "shearY": 15},
            {"name": "chain3", "parent": "chain2", "x": 30},
        ],
        "slots": [
            {"name": "boxA", "bone": "base", "attachment": "boxA"},
            {"name": "boxB", "bone": "base", "attachment": "boxB"},
            {"name": "boxC", "bone": "base", "attachment": "boxC"},
            {"name": "boxSkin", "bone": "skinbone", "attachment": "boxSkin"},
            {"name": "boxSlid", "bone": "base", "attachment": "slidPose"},
        ],
        # 4.2 has no sliders and ignores "constraints"
        "constraints": [{"name": "slid", "type": "slider", "animation": "slide"}],
        "skins": [
            {"name": "default", "attachments": {
                "boxA": {"boxA": square(-50, -50, 50, 50)},
                "boxB": {"boxB": square(-30, -30, 70, 70)},
                "boxC": {"boxC": square(-10, -10, 90, 90)},
                "boxSkin": {"boxSkin": square(-20, -20, 20, 20)},
                "boxSlid": {"slidPose": square(300, -20, 340, 20), "slidApplied": square(300, -20, 340, 20)},
            }},
            {"name": "extra", "bones": ["skinbone"]},
        ],
        "animations": {
            # the offsets draw boxC, boxB, boxA (reverse of setup slot order)
            "reorder": {"drawOrder": [{"offsets": [{"slot": "boxA", "offset": 2}, {"slot": "boxC", "offset": -2}]}]},
            "slide": {"slots": {"boxSlid": {"attachment": [{"name": "slidApplied"}]}}},
        },
    }


def main():
    check = sys.argv[1:] == ["--check"]
    root = pathlib.Path(__file__).resolve().parent / "assets"
    bad = 0
    for line, version in VERSIONS.items():
        path = root / line / NAME
        text = json.dumps(fixture(version), indent=1) + "\n"
        if not check:
            path.write_text(text)
        elif not path.is_file() or path.read_text() != text:
            print(f"{path}: differs from the generator's output")
            bad = 1
        else:
            print(f"{path}: matches")
    return bad


if __name__ == "__main__":
    sys.exit(main())
