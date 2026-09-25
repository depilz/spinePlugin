#!/bin/bash
# Skins harness build: the shared host.c preloading realdata_fixture (skins_fixture.cpp) and skins_probe, the
# checkout's SkeletonDataHolder.cpp (the fixture's loadData builds the real holder) + the shared host's bindings,
# runtime and Lua objects. Reads the plugin tree read-only.
#   build.sh asan   -> $OUT/host_asan    (ASan+UBSan)
#   build.sh plain  -> $OUT/host_plain   (no sanitizers)
# OUT defaults to $SUITE_OUT, else $SPINE_TEST_OUT/skins. Environment: tests/host/host.sh.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../host/host.sh"
MODE="${1:-asan}"
OUT="${OUT:-${SUITE_OUT:-$SPINE_TEST_OUT/skins}}"
host_build "$MODE" "$OUT/host_$MODE" "realdata_fixture skins_probe" \
  "$W/skins_fixture.cpp" "$W/skins_probe.cpp" "$SPINE_REPO/shared/SkeletonDataHolder.cpp"
echo "built $OUT/host_$MODE"
