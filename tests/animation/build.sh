#!/bin/bash
# Animation harness build: the shared host.c preloading realdata_fixture, built from animation_fixture.cpp (the shared
# headless fixture plus createPlugin/rawTrackCount/entryPtr) + the shared host's bindings, runtime and Lua objects.
# Reads the plugin tree read-only.
#   build.sh asan   -> $OUT/host_asan    (ASan+UBSan)
#   build.sh plain  -> $OUT/host_plain   (no sanitizers)
# OUT defaults to $SUITE_OUT, else $SPINE_TEST_OUT/animation. Environment: tests/host/host.sh.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../host/host.sh"
MODE="${1:-asan}"
OUT="${OUT:-${SUITE_OUT:-$SPINE_TEST_OUT/animation}}"
host_build "$MODE" "$OUT/host_$MODE" realdata_fixture "$W/animation_fixture.cpp"
echo "built $OUT/host_$MODE"
