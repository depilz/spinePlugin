#!/bin/bash
# yflip: the gap-4 Y-flip matrix against the checkout's runtime and bindings, ASan+UBSan builds. Five processes, each a
# test of its own (exit 0, sanitizer-clean, at least one check row): the bench's matrix and minimal probe, and the Lua
# tests l1/l2/l3 in the yflip host. Then one test per check row they print ("matrix cloud-pot 4 idle wind=25 ...").
# Configuration A is the plugin's, read from the checkout by build.sh, so a coordinate fix there moves these checks.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
"$W/build.sh" asan
SPINES="${SPINE_SPINES:-$SPINE_REPO/Corona/spines}"
TESTS=(matrix probe l1_physics_api l2_lua_visible l3_lua_gravity)

matrix() ( cd "$SPINES" && YFLIP_ALL=1 YFLIP_SPINES="$W/spines" "$SUITE_OUT/bench_asan" checkout "$SUITE_OUT/matrix_detail.txt" )
probe() ( cd "$SPINES" && YFLIP_PROBE="$W/spines" "$SUITE_OUT/bench_asan" checkout )

# rows test: runs the test with its stdout (table and check rows) in $SUITE_OUT/<test>.out; true once it printed a row
rows() {
  local out="$SUITE_OUT/$1.out"
  case "$1" in matrix|probe) "$1" >"$out" ;; *) "$W/run.sh" "$W/$1.lua" >"$out" ;; esac || return 1
  grep -qE $'^(PASS|FAIL)\t' "$out"
}
for t in "${TESTS[@]}"; do
  run_test "$t" rows "$t"
  while IFS=$'\t' read -r verdict id; do
    case "$verdict" in PASS|FAIL) record "$verdict" "$id" ;; esac
  done <"$SUITE_OUT/$t.out"
done
