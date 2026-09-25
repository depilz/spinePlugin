#!/bin/bash
# skins: the s1 API contract in the ASan+UBSan skins host (real bindings and runtime, skins fixture). One process;
# test "s1_api_contract" is that process (exit 0, sanitizer-clean, summary printed), then one test per contract row
# ("s1_api_contract A1" ...), PASS/FAIL as the row printed it against the final API spec.
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
