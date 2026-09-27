#!/bin/bash
# Split harness build: tests/splitfx/build.sh with operator new counted in asan (the render-11 check).
#   build.sh [asan|plain] -> $OUT/host_<mode>; OUT defaults to $SUITE_OUT, else $SPINE_TEST_OUT/split.
set -euo pipefail
exec "$(dirname "$0")/../splitfx/build.sh" split "$@"
