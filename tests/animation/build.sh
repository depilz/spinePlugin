#!/bin/bash
# Animation harness build: the lifecycle host (tests/lifecycle/build.sh: host.c + the repo's real shared/*.cpp,
# Lua_Spine.cpp's create() included) plus animation_fixture.cpp's native helpers in __native.
# Reads the plugin tree read-only.
#   build.sh asan   -> $OUT/host_asan    (ASan+UBSan)
#   build.sh plain  -> $OUT/host_plain   (no sanitizers)
# OUT defaults to $SUITE_OUT, else $SPINE_TEST_OUT/animation. Environment: tests/host/host.sh.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-asan}"
OUT="${OUT:-${SUITE_OUT:-${SPINE_TEST_OUT:?SPINE_TEST_OUT must name the build output directory}/animation}}" \
  exec "$W/../lifecycle/build.sh" "$MODE" -DHOST_NATIVE=animation_native "$W/animation_fixture.cpp"
