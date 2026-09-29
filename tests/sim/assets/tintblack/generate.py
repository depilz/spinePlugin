#!/usr/bin/env python3
"""Writes the synthetic tint-black fixture, one export per runtime line: <out>/<line>/ with
tintblack.json, tintblack.atlas and its pages tintblack.png, tintblack2.png.

Usage: python3 tests/sim/assets/tintblack/generate.py [out]   (default out: this script's folder)
Pure stdlib. The committed files are this script's output byte for byte; edit the tables below, never the files.

Each page is a straight-alpha swatch grid: column i is COLORS[i] (page 2: PAGE2_COLORS[i]), row j is ALPHAS[j], in
BLOCK x BLOCK texel blocks. Every slot shows the whole page 1 region `tex` (page size, scale 1) on its own bone.
Animations: `pulse` keys slot `pulse`'s dark colour (rgba2, light held white) through red, blue and black;
`swap` switches slot `swap` from `tex` (page 1) to `tex2` (page 2).
"""
import json
import struct
import sys
import zlib
from pathlib import Path

COLORS = [(255, 255, 255), (0, 0, 0), (255, 0, 0), (0, 255, 0), (128, 128, 128), (200, 100, 50), (64, 160, 220),
          (30, 60, 90)]
PAGE2_COLORS = COLORS[::-1]
ALPHAS = [0, 64, 128, 192, 255]
BLOCK = 16
W, H = BLOCK * len(COLORS), BLOCK * len(ALPHAS)
VERSIONS = {"4.2": "4.2.22", "4.3": "4.3.75-beta"}

# name, blend, light (rrggbbaa), dark (rrggbb, None = no dark colour)
SLOTS = [
    ("normal", "normal", "ffcc66ff", "3399ff"),
    ("pulse", "normal", "ffffffff", "ff0000"),
    ("additive", "additive", "ffcc66ff", "3399ff"),
    ("alpha", "normal", "4de69980", "808080"),
    ("multiply", "multiply", "ffcc66ff", "3399ff"),
    ("screen", "screen", "ffcc66ff", "3399ff"),
    ("darkblack", "normal", "ff8040ff", "000000"),
    ("nodark", "normal", "ff8040ff", None),
    ("lightblack", "normal", "000000ff", "7e7e7e"),
    ("swap", "normal", "ffffffff", "3399ff"),
]
COLUMNS, PITCH_X, PITCH_Y = 2, 220, 140


def page(colors):
    rgba = bytearray(W * H * 4)
    for y in range(H):
        for x in range(W):
            rgba[(y * W + x) * 4:(y * W + x + 1) * 4] = bytes(colors[x // BLOCK] + (ALPHAS[y // BLOCK],))
    return rgba


def png(rgba):
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
    raw = b"".join(b"\0" + bytes(rgba[y * W * 4:(y + 1) * W * 4]) for y in range(H))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def atlas():
    pages = [("tintblack.png", "tex"), ("tintblack2.png", "tex2")]
    return "\n".join("%s\n\tsize: %d, %d\n\tfilter: Linear, Linear\n%s\n\tbounds: 0, 0, %d, %d\n" % (p, W, H, r, W, H)
                   for p, r in pages)


def skeleton(version):
    rows = (len(SLOTS) + COLUMNS - 1) // COLUMNS
    bones, slots, skin = [{"name": "root"}], [], {}
    for k, (name, blend, light, dark) in enumerate(SLOTS):
        x = (k % COLUMNS - (COLUMNS - 1) / 2) * PITCH_X
        y = ((rows - 1) / 2 - k // COLUMNS) * PITCH_Y
        bones.append({"name": "b_" + name, "parent": "root", "x": int(x), "y": int(y)})
        slot = {"name": name, "bone": "b_" + name, "color": light}
        if dark:
            slot["dark"] = dark
        slot["attachment"] = "tex"
        if blend != "normal":
            slot["blend"] = blend
        slots.append(slot)
        skin[name] = {"tex": {"width": W, "height": H}}
    skin["swap"]["tex2"] = {"width": W, "height": H}
    width, height = COLUMNS * PITCH_X, rows * PITCH_Y
    return {
        "skeleton": {"hash": "tintblack", "spine": version, "x": -width // 2, "y": -height // 2, "width": width,
                     "height": height},
        "bones": bones,
        "slots": slots,
        "skins": [{"name": "default", "attachments": skin}],
        "animations": {
            "pulse": {"slots": {"pulse": {"rgba2": [
                {"time": 0, "light": "ffffffff", "dark": "ff0000"},
                {"time": 1, "light": "ffffffff", "dark": "0000ff"},
                {"time": 2, "light": "ffffffff", "dark": "000000"},
            ]}}},
            "swap": {"slots": {"swap": {"attachment": [{"time": 0, "name": "tex"}, {"time": 0.5, "name": "tex2"}]}}},
        },
    }


def main(out):
    pages = {"tintblack.png": png(page(COLORS)), "tintblack2.png": png(page(PAGE2_COLORS))}
    for line, version in VERSIONS.items():
        d = out / line
        d.mkdir(parents=True, exist_ok=True)
        (d / "tintblack.json").write_text(json.dumps(skeleton(version), indent=1) + "\n")
        (d / "tintblack.atlas").write_text(atlas())
        for name, data in pages.items():
            (d / name).write_bytes(data)


if __name__ == "__main__":
    main(Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent)
