#!/bin/bash
# worldspace: every scenario in ./scenarios in the ASan+UBSan worldspace host (the lifecycle host: the real plugin
# entry over tests/lifecycle/solar2d_stub.lua, plus the __probe SkeletonBounds oracle), one process per scenario;
# then whether gen_fixture.py still writes the committed fixture.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
"$W/build.sh" asan
while read -r script args; do
  [[ -z "$script" || "$script" == \#* ]] && continue
  run_test "${script%.lua}${args:+ $args}" "$W/run.sh" "$W/$script" $args
done <"$W/scenarios"
run_test "gen_fixture check" python3 "$W/gen_fixture.py" --check
