#!/bin/bash
# probe-batching: every scenario in ./scenarios in the ASan+UBSan probe-batching host (plugin + splitfx oracle with its
# unbatched per-slot reference against the Solar2D mock), one process per scenario.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
"$W/build.sh" asan
while read -r script args; do
  [[ -z "$script" || "$script" == \#* ]] && continue
  run_test "${script%.lua}${args:+ $args}" "$W/run.sh" "$W/$script" $args
done <"$W/scenarios"
