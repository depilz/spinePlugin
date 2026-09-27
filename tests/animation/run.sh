#!/bin/bash
# run.sh [--plain] test.lua [args...]   (cwd = $SPINE_SPINES, default $SPINE_REPO/Corona/spines; line: SPINE_RUNTIME)
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
OUT="${OUT:-${SUITE_OUT:-${SPINE_TEST_OUT:?SPINE_TEST_OUT must name the build output directory}/animation}}"
source "$W/../host/host.sh"
BIN="$OUT/host_asan"
if [[ "${1:-}" == "--plain" ]]; then BIN="$OUT/host_plain"; shift; fi
T="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; shift
cd "${SPINE_SPINES:-$SPINE_REPO/Corona/spines}"
"$BIN" "$T" "$@"
