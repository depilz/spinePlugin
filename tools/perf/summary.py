#!/usr/bin/env python3
"""Reduces the raw runs of tools/perf/sim-perf.sh or bench-ref.sh: summary.py <out>.
Reads <out>/raw/<label>-r<round>.log (and .footprint), drops round 1 (warm-up) and, for sim-perf, every run that
<out>/runs.tsv does not mark identity PASS and scenario PASS, then prints one TSV row per label and metric:
label, metric, n, median, min, max.
"""
import re
import statistics
import sys
from collections import defaultdict
from pathlib import Path

# (metric names, pattern over a results or bench line); a group per name
LINE_METRICS = [
    (("work_avg_ms", "work_p50_ms", "work_p95_ms"),
     re.compile(r"^(?:COST )?updateState\+draw .*?avg ([\d.]+) ms, p50 ([\d.]+), p95 ([\d.]+)")),
    (("interval_avg_ms",), re.compile(r"^(?:COST )?enterFrame interval: avg ([\d.]+) ms")),
    (("create_ms",), re.compile(r"^create x\d+: ([\d.]+) ms")),
    (("lua_gc_delta_kb",), re.compile(r"collector running\): mean (-?[\d.]+) KB")),
    (("lua_alloc_kb",), re.compile(r"collector stopped \(mean of \d+ frames\): (-?[\d.]+) KB")),
    (("meshes",), re.compile(r"^meshes at end:\t(\d+)")),
]
MARK_LUA = re.compile(r"^MARK\t(\w+)\tlua (\d+) KB")
BENCH = re.compile(r"^ref (\S+) us/frame batched=([\d.]+) passthrough=([\d.]+)")
FOOTPRINT = re.compile(r"Footprint: (\d+) B")


def run_metrics(log: Path):
    """metric -> value of one run's log and its .footprint samples"""
    m = {}
    for line in log.read_text(errors="replace").splitlines():
        for names, pat in LINE_METRICS:
            hit = pat.search(line)
            if hit:
                m.update(zip(names, map(float, hit.groups())))
        hit = MARK_LUA.match(line)
        if hit:
            m["lua_kb_" + hit[1]] = float(hit[2])
        hit = BENCH.match(line)
        if hit:
            m[hit[1] + " batched_us"], m[hit[1] + " passthrough_us"] = float(hit[2]), float(hit[3])
    fp = log.with_suffix(".footprint")
    if fp.exists():
        mark = None
        for line in fp.read_text(errors="replace").splitlines():
            if line.startswith("MARK "):
                mark = line.split()[1]
            hit = FOOTPRINT.search(line)
            if hit and mark:
                m["footprint_mb_" + mark] = int(hit[1]) / 2**20
                mark = None
    return m


def main():
    out = Path(sys.argv[1])
    kept = None
    runs = out / "runs.tsv"
    if runs.exists():
        rows = [line.split("\t") for line in runs.read_text().splitlines()[1:]]
        kept = {(r[0], r[1]) for r in rows if r[2] == "PASS" and r[3] == "PASS"}
    values = defaultdict(lambda: defaultdict(list))
    for log in sorted((out / "raw").glob("*-r*.log")):
        label, rnd = log.stem.rsplit("-r", 1)
        if rnd == "1" or (kept is not None and (label, rnd) not in kept):
            continue
        for metric, v in run_metrics(log).items():
            values[label][metric].append(v)
    print("label\tmetric\tn\tmedian\tmin\tmax")
    for label, metrics in values.items():
        for metric, vs in metrics.items():
            print("%s\t%s\t%d\t%.3f\t%.3f\t%.3f" % (label, metric, len(vs), statistics.median(vs), min(vs), max(vs)))


main()
