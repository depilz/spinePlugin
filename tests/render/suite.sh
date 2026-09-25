#!/bin/bash
# render: every scenario in ./scenarios in the ASan+UBSan render host (plugin + renderfx oracle against the Solar2D
# mock), one process per scenario; h1_stale_world in the shared host; the native bench with a few frames.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
"$W/build.sh" asan
while read -r script args; do
  [[ -z "$script" || "$script" == \#* ]] && continue
  run_test "${script%.lua}${args:+ $args}" "$W/run.sh" "$W/$script" $args
done <"$W/scenarios"
host=$("$W/../host/build.sh" asan)
cd "$SPINE_SPINES"
run_test h1_stale_world "$host" "$W/h1_stale_world.lua"
run_test "bench 5" "$SUITE_OUT/bench_asan" 5
