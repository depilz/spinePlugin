#!/bin/bash
# animation: every scenario in ./scenarios in the ASan+UBSan animation host (the lifecycle host: the real plugin
# entry over tests/lifecycle/solar2d_stub.lua), one process per scenario; then whether a listener's error reaches the
# output at all.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
"$W/build.sh" asan
while read -r script args; do
  [[ -z "$script" || "$script" == \#* ]] && continue
  run_test "${script%.lua}${args:+ $args}" "$W/run.sh" "$W/$script" $args
done <"$W/scenarios"

# reports_error message command...: prints the command's output; true when the listener's error(message) reached the
# stubbed CoronaLuaDoCall and the plugin call that raised it still returned normally
reports_error() {
  local message=$1 out
  shift
  out=$("$@" 2>&1) || true
  printf '%s\n' "$out"
  grep -q "^CoronaLuaDoCall: .*$message" <<<"$out" && grep -q 'pcall ok =.true' <<<"$out"
}
run_test "t4_reentrancy error reported" reports_error "boom in listener" "$W/run.sh" "$W/t4_reentrancy.lua" error
run_test "t15_on_complete error reported" reports_error "boom in onComplete" "$W/run.sh" "$W/t15_on_complete.lua" error
run_test "t16_group_dispatch error reported" reports_error "boom in group listener" "$W/run.sh" "$W/t16_group_dispatch.lua" error
