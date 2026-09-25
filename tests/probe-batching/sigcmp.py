#!/usr/bin/env python3
# compare two per-frame display-list signature files written with PB_SIG=<file> by pb_place/pb_meshcount
# ("<frame id> | <main sig> | <split sig>[ #BAD]"), e.g. before and after a fix: sigcmp.py a.sig b.sig labelA labelB
# reports: baseline-good frames whose display list changed; baseline-bad frames fixed/unchanged; bad counts
import sys
def load(p):
    d = {}
    for line in open(p):
        line = line.rstrip("\n"); bad = line.endswith(" #BAD")
        if bad: line = line[:-5]
        k, rest = line.split(" | ", 1)
        d[k] = (rest, bad)
    return d
a, b = load(sys.argv[1]), load(sys.argv[2])
goodChanged = sum(1 for k in a if k in b and not a[k][1] and a[k][0] != b[k][0])
badChanged = sum(1 for k in a if k in b and a[k][1] and a[k][0] != b[k][0])
badSame = sum(1 for k in a if k in b and a[k][1] and a[k][0] == b[k][0])
print("%-9s -> %-9s frames=%d baseline-good frames changed=%d | baseline-bad changed=%d unchanged=%d | bad %d -> %d" % (
    sys.argv[3], sys.argv[4], len(a), goodChanged, badChanged, badSame, sum(1 for k in a if a[k][1]), sum(1 for k in b if b[k][1])))
