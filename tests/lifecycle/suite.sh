#!/bin/bash
# lifecycle: every scenario in ./scenarios in the ASan+UBSan lifecycle host (host.c + solar2d_stub.lua over the
# repo's real shared/*.cpp), one process per scenario; then the host's exit on enterFrame listener errors.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
"$W/build.sh" asan
while read -r script args; do
  [[ -z "$script" || "$script" == \#* ]] && continue
  run_test "${script%.lua}${args:+ $args}" "$W/run.sh" "$W/$script" $args
done <"$W/scenarios"

# host_frame_errors: the host itself exits 1 on an enterFrame listener error the scenario did not expect and 0 on one
# it did (run without run.sh, whose report grep would fail the unexpected one on its own)
host_frame_errors() {
  local stub="$W/solar2d_stub.lua" t="$W/t41_frame_error.lua"
  ! "$SUITE_OUT/host_asan" "$stub" "$t" unexpected && "$SUITE_OUT/host_asan" "$stub" "$t" expected
}
run_test "t41_frame_error host exit" host_frame_errors
