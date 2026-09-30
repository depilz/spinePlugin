#!/bin/bash
# Headless CPU reference (evidence, not a test suite): render() per frame of the line's batching SkeletonRenderer vs
# the pass-through tests/splitfx/ref_renderer.cpp, from the plain (no sanitizer) build of tests/render/bench.cpp,
# `bench <frames> ref` run <runs> times over the bench's examples:
#   tools/perf/bench-ref.sh <out> <runs> [frames]   (frames per animation, default 300)
# Writes <out>/raw/bench-r<run>.log; tools/perf/summary.py <out> reduces them, discarding run 1.
# Environment: SDKROOT as for tests/run.sh; SPINE_REPO (default: this checkout); SPINE_RUNTIME (default 4.2).
set -euo pipefail
TOOLS="$(cd "$(dirname "$0")" && pwd)"
(( $# >= 2 )) || { echo "usage: $0 <out> <runs> [frames]" >&2; exit 2; }
: "${SDKROOT:?set SDKROOT as for tests/run.sh}"
RUNS=$2 FRAMES=${3:-300}
mkdir -p "$1/raw"
OUT=$(cd "$1" && pwd)
export SPINE_REPO=${SPINE_REPO:-$(cd "$TOOLS/../.." && pwd)} SPINE_RUNTIME=${SPINE_RUNTIME:-4.2}
export SPINE_TEST_OUT=$OUT/test-out
OUT=$OUT/render "$TOOLS/../../tests/render/build.sh" plain
source "$TOOLS/../../tests/host/spines.sh"
cd "$(line_spines "$SPINE_RUNTIME")"
for ((run = 1; run <= RUNS; run++)); do
  "$OUT/render/bench_plain" "$FRAMES" ref | tee "$OUT/raw/bench-r$run.log"
done
