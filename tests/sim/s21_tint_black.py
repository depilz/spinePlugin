#!/usr/bin/env python3
"""Checks the captures of s21_tint_black.lua and prints its CHECK lines (simlib's TAB-separated format), which
suite.sh appends to the scenario's results file: s21_tint_black.py <results file> <stdout log>.

Every visible slot of the tintblack fixture is sampled at each texel block centre, placed from the saved image's size
(D17: the pixel scale is image size / background size, whatever the Simulator's skin), as the median of a 5x5 patch.
The reference is Spine's tint-black formula on straight texels (c, a_t), light (L, A) and dark D,
    src.rgb = a_t * A * ((1 - c) * D + c * L),  src.a = a_t * A
(D = 0 for no dark colour: the default shader), composited with the slot's blend over the opaque background. While a
user effect is set the dark term is dropped and the effect's kernel (brightness, desaturate) applied instead.
Checks:
  <capture>     every block within TOL levels of the reference; a capture in IDENTICAL also has 0 pixels differing
                from setup
  discriminates some tinted block of setup is more than TOL levels from the same slot with dark = black
  nodark        the no-dark and dark-black slots match the default-shader reference in every capture without a user
                effect
  sampling      every patch's spread is at most 1 level: the samples sit inside their texel blocks
  log           the Simulator's stdout has no duplicate-define error and no plugin warning
"""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path[:0] = [str(HERE), str(HERE / "assets" / "tintblack")]
import pnglib  # noqa: E402
from generate import ALPHAS, BLOCK, COLORS, H, PAGE2_COLORS, SLOTS, W, skeleton  # noqa: E402

BG = (40, 80, 120)
TOL, SPREAD = 3, 1
IDENTICAL = {"flashclear", "desatclear", "pulseback", "swapback", "unhide", "reassemble"}
DESATURATE = (0.2125, 0.7154, 0.0721)
# The trailing colon keeps out Solar2D's "WARNING: plugin.spine43 is not configured in build.settings" line.
LOG_ERRORS = ("Could not create custom effect", "WARNING: plugin.spine:")
BONES = {b["name"][2:]: (b["x"], b["y"]) for b in skeleton("")["bones"][1:]}


def hexf(h):
    return tuple(int(h[i:i + 2], 16) / 255 for i in range(0, len(h), 2))


BASE = {name: {"blend": blend, "light": hexf(light), "dark": hexf(dark) if dark else None, "page": COLORS}
        for name, blend, light, dark in SLOTS}


def state(capture):
    """(slots, user effect) the capture should show: slot name -> its state (hidden slots left out)."""
    slots = {name: dict(s) for name, s in BASE.items()}
    effect = {"flash": ("brightness", 0.3), "desat": ("desaturate", 0.5), "desat1": ("desaturate", 1.0)}.get(capture)
    if capture == "pulse":
        slots["pulse"]["dark"] = (0.5, 0.0, 0.5)  # rgba2 ff0000 -> 0000ff, half-way
    elif capture == "pulseblack":
        slots["pulse"]["dark"] = (0.0, 0.0, 0.0)
    elif capture == "swap":
        slots["swap"]["page"] = slots["additive"]["page"] = PAGE2_COLORS
    elif capture == "hide":
        del slots["normal"]
    return slots, effect


def blend(mode, src, sa, bg):
    if mode == "additive":
        return [src[k] + bg[k] for k in range(3)]
    if mode == "multiply":
        return [src[k] * bg[k] + bg[k] * (1 - sa) for k in range(3)]
    if mode == "screen":
        return [src[k] + bg[k] * (1 - src[k]) for k in range(3)]
    return [src[k] + bg[k] * (1 - sa) for k in range(3)]


def reference(slot, color, alpha, effect, dark_off=False):
    """The block's expected 0..255 rgb."""
    c, at = [v / 255 for v in color], alpha / 255
    light, a = slot["light"][:3], slot["light"][3]
    dark = (0, 0, 0) if effect or dark_off or not slot["dark"] else slot["dark"]
    src = [at * a * ((1 - c[k]) * dark[k] + c[k] * light[k]) for k in range(3)]
    if effect and effect[0] == "brightness":
        src = [min(1.0, at * a * (c[k] + effect[1]) * light[k]) for k in range(3)]
    elif effect:
        lum = sum(src[k] * DESATURATE[k] for k in range(3))
        src = [src[k] + (lum - src[k]) * effect[1] for k in range(3)]
    out = blend(slot["blend"], src, at * a, [v / 255 for v in BG])
    return [255 * min(1.0, max(0.0, v)) for v in out]


def blocks(img, bw, bh, ox, oy, name):
    """(column, row, median rgba, spread) of every texel block of the slot's region in the capture."""
    sx, sy = img[0] / bw, img[1] / bh
    bx, by = BONES[name]
    left, top = ox + bx - W / 2, oy - by - H / 2
    for j in range(len(ALPHAS)):
        for i in range(len(COLORS)):
            cx, cy = int((left + (i + 0.5) * BLOCK) * sx), int((top + (j + 0.5) * BLOCK) * sy)
            yield (i, j) + pnglib.median_patch(img, cx, cy)


def check(name, ok, *detail):
    print("\t".join(["CHECK", "PASS" if ok else "FAIL", name] + [str(d) for d in detail]))


def main(results, stdout):
    lines = [line.split("\t") for line in Path(results).read_text().splitlines()]
    captures = {f[1]: (Path(results).parent / f[2], *map(float, f[3:7])) for f in lines if f[0] == "CAPTURE"}
    expected = [f[1] for f in lines if f[0] == "EXPECT"]
    images, spread_worst, discriminates, nodark = {}, (0, ""), (0.0, ""), (0.0, "")
    for capture in [e for e in expected if e not in ("define", "sampling", "log", "discriminates", "nodark")]:
        if capture not in captures or not captures[capture][0].exists():
            check(capture, False, "no capture")
            continue
        path, bw, bh, ox, oy = captures[capture]
        img = images[capture] = pnglib.load(path)
        slots, effect = state(capture)
        worst, fails = (0.0, ""), 0
        for name, slot in slots.items():
            tinted = not effect and slot["dark"] and any(slot["dark"])
            for i, j, v, spread in blocks(img, bw, bh, ox, oy, name):
                where = "%s %s block %d,%d measured %s" % (capture, name, i, j, tuple(v[:3]))
                spread_worst = max(spread_worst, (spread, where))
                ref = reference(slot, slot["page"][i], ALPHAS[j], effect)
                dev = [abs(v[k] - ref[k]) for k in range(3)]
                fails += any(d > TOL for d in dev)
                at = "%s reference %s" % (where, tuple(round(r, 2) for r in ref))
                worst = max(worst, (max(dev), at))
                if not effect and not tinted:
                    nodark = max(nodark, (max(dev), at))
                if capture == "setup" and tinted:
                    plain = reference(slot, slot["page"][i], ALPHAS[j], effect, dark_off=True)
                    discriminates = max(discriminates, (max(abs(v[k] - plain[k]) for k in range(3)), where))
        detail = ["blocks out of bound %d" % fails, "worst |measured - reference| %.2f at %s" % worst,
                  "image %dx%d scale %.4f" % (img[0], img[1], img[0] / bw)]
        if capture in IDENTICAL:
            differing = pixels_differing(images.get("setup"), img)
            detail.append("pixels differing from setup %d" % differing)
            fails += differing
        check(capture, fails == 0, *detail)
    if "discriminates" in expected:
        check("discriminates", discriminates[0] > TOL,
              "largest |measured - dark-black reference| %.2f at %s" % discriminates)
    if "nodark" in expected:
        check("nodark", nodark[0] <= TOL, "worst |measured - default-shader reference| %.2f at %s" % nodark)
    check("sampling", bool(images) and spread_worst[0] <= SPREAD, "largest 5x5 spread %d at %s" % spread_worst)
    bad = [line for line in Path(stdout).read_text(errors="replace").splitlines() if any(e in line for e in LOG_ERRORS)]
    check("log", not bad, *(bad[:3] or ["no duplicate-define error or plugin warning"]))


def pixels_differing(a, b):
    """Pixels that differ between two decoded images (all of them when either is missing or the sizes differ)."""
    if not a or not b or a[:2] != b[:2]:
        return max(a[0] * a[1] if a else 0, b[0] * b[1] if b else 0, 1)
    return sum(a[2][p * 4:p * 4 + 4] != b[2][p * 4:p * 4 + 4] for p in range(a[0] * a[1]))


if __name__ == "__main__":
    main(*sys.argv[1:3])
