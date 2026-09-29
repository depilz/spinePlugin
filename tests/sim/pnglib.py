"""Pure-stdlib PNG decoding for the Simulator pixel scenarios: load() reads an 8-bit, non-interlaced PNG of any colour
type (grey, RGB, palette, grey+alpha, RGBA) with all five scanline filters into RGBA bytes; median_patch() samples it.
"""
import struct
import zlib

CHANNELS = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}


def unfilter(raw, width, height, bpp):
    """The scanlines of a decompressed IDAT stream with their filters (None, Sub, Up, Average, Paeth) undone."""
    stride = width * bpp
    out, prev = bytearray(height * stride), bytearray(stride)
    for y in range(height):
        o = y * (stride + 1)
        f, line = raw[o], bytearray(raw[o + 1:o + 1 + stride])
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            c = prev[x - bpp] if x >= bpp else 0
            up = prev[x]
            if f == 1:
                line[x] = (line[x] + a) & 255
            elif f == 2:
                line[x] = (line[x] + up) & 255
            elif f == 3:
                line[x] = (line[x] + ((a + up) >> 1)) & 255
            elif f == 4:
                pa, pb, pc = abs(up - c), abs(a - c), abs(a + up - 2 * c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else up if pb <= pc else c)) & 255
        out[y * stride:(y + 1) * stride] = prev = line
    return out


def load(path):
    """(width, height, rgba bytearray) of the PNG at path."""
    b = open(path, "rb").read()
    assert b[:8] == b"\x89PNG\r\n\x1a\n", path
    i, idat, plte, trns = 8, b"", b"", b""
    while i < len(b):
        n, tag = struct.unpack(">I4s", b[i:i + 8])
        data = b[i + 8:i + 8 + n]
        i += 12 + n
        if tag == b"IHDR":
            w, h, depth, ct, _, _, interlace = struct.unpack(">IIBBBBB", data)
            assert depth == 8 and interlace == 0, (path, depth, interlace)
        elif tag == b"IDAT":
            idat += data
        elif tag == b"PLTE":
            plte = data
        elif tag == b"tRNS":
            trns = data
    bpp = CHANNELS[ct]
    px = unfilter(zlib.decompress(idat), w, h, bpp)
    rgba = bytearray(w * h * 4)
    for k in range(w * h):
        s = px[k * bpp:(k + 1) * bpp]
        if ct == 6:
            rgba[k * 4:k * 4 + 4] = s
        elif ct == 2:
            rgba[k * 4:k * 4 + 4] = s + b"\xff"
        elif ct == 0:
            rgba[k * 4:k * 4 + 4] = bytes((s[0], s[0], s[0], 255))
        elif ct == 4:
            rgba[k * 4:k * 4 + 4] = bytes((s[0], s[0], s[0], s[1]))
        else:
            rgba[k * 4:k * 4 + 3] = plte[s[0] * 3:s[0] * 3 + 3]
            rgba[k * 4 + 3] = trns[s[0]] if s[0] < len(trns) else 255
    return w, h, rgba


def median_patch(img, cx, cy, r=2):
    """(per-channel RGBA median, largest RGB max-min spread) of the (2r+1)^2 pixels centred on (cx, cy)."""
    w, _, d = img
    around = [(x, y) for y in range(cy - r, cy + r + 1) for x in range(cx - r, cx + r + 1)]
    vals = [d[(y * w + x) * 4:(y * w + x + 1) * 4] for x, y in around]
    median = tuple(sorted(v[c] for v in vals)[len(vals) // 2] for c in range(4))
    return median, max(max(v[c] for v in vals) - min(v[c] for v in vals) for c in range(3))
