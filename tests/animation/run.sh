#!/bin/bash
# run.sh [--plain] test.lua [args...]   (cwd = $SPINE_SPINES, default $SPINE_REPO/Corona/spines; line: SPINE_RUNTIME)
# The animation host runs the script over the lifecycle suite's Solar2D stub (tests/lifecycle/run.sh).
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
OUT="${OUT:-${SUITE_OUT:-${SPINE_TEST_OUT:?SPINE_TEST_OUT must name the build output directory}/animation}}" \
  exec "$W/../lifecycle/run.sh" "$@"
