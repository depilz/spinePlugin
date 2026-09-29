#!/bin/bash
# skins: the s1 API contract in the ASan+UBSan skins host (real bindings and runtime, skins fixture). One process;
# test "s1_api_contract" is that process (exit 0, sanitizer-clean, summary printed), then one test per contract row
# ("s1_api_contract A1" ...), PASS/FAIL as the row printed it against the final API spec. Then the stress scripts, one
# host process per test, PASS when it exits 0 sanitizer-clean (each asserts its own mismatch/memory/teardown checks).
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
"$W/build.sh" asan
ROWS="$SUITE_OUT/s1_api_contract.out"

# contract: runs s1 with its rows on their own stream (stderr warnings would split them); true once it summarised
contract() {
  "$W/run.sh" "$W/s1_api_contract.lua" >"$ROWS" || return 1
  grep -q '^== s1 summary: ' "$ROWS"
}
run_test s1_api_contract contract
while read -r verdict id _; do
  case "$verdict" in PASS|FAIL) record "$verdict" "s1_api_contract $id" ;; esac
done <"$ROWS"

# s4 runs each seed twice, as two separate host processes; the 4.3 line runs the seeds its evidence covered
SEEDS="1 2 3 7 11"
[[ "$SPINE_RUNTIME" == 4.2 ]] || SEEDS="1 7"
for seed in $SEEDS; do
  for run in 1 2; do run_test "s4_final_stress seed$seed run$run" "$W/run.sh" "$W/s4_final_stress.lua" "$seed"; done
done
run_test s6_readonly_vs_pin "$W/run.sh" "$W/s6_readonly_vs_pin.lua"
for mode in find inplace; do run_test "s7_avatar_mix $mode" "$W/run.sh" "$W/s7_avatar_mix.lua" 60 800 "$mode"; done
