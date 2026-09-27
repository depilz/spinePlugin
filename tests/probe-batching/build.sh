#!/bin/bash
# Probe-batching harness build: tests/splitfx/build.sh with operator new accounting off in asan.
#   build.sh [asan|plain] -> $OUT/host_<mode>; OUT defaults to $SUITE_OUT, else $SPINE_TEST_OUT/probe-batching.
set -euo pipefail
NO_COUNTED_NEW=1 exec "$(dirname "$0")/../splitfx/build.sh" probe-batching "$@"
