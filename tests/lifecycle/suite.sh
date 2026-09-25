#!/bin/bash
# lifecycle: every scenario in ./scenarios in the ASan+UBSan lifecycle host (host.c + solar2d_stub.lua over the
# repo's real shared/*.cpp), one process per scenario.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
"$W/build.sh" asan
while read -r script args; do
  [[ -z "$script" || "$script" == \#* ]] && continue
  run_test "${script%.lua}${args:+ $args}" "$W/run.sh" "$W/$script" $args
done <"$W/scenarios"
