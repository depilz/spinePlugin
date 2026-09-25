#!/bin/bash
# animation: every scenario in ./scenarios in the ASan+UBSan animation host (real bindings and runtime, headless
# fixture), one process per scenario; then whether a listener's error reaches the output at all.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
"$W/build.sh" asan
while read -r script args; do
  [[ -z "$script" || "$script" == \#* ]] && continue
  run_test "${script%.lua}${args:+ $args}" "$W/run.sh" "$W/$script" $args
done <"$W/scenarios"

# reports_error command...: prints the command's output; true when it carries t4's error("boom in listener")
reports_error() {
  local out
  out=$("$@" 2>&1) || true
  printf '%s\n' "$out"
  grep -q 'boom in listener' <<<"$out"
}
run_test "t4_reentrancy error reported" reports_error "$W/run.sh" "$W/t4_reentrancy.lua" error
