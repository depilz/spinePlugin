#!/bin/bash
# Runs every scenario in ./scenarios and prints one verdict line each (build first: build.sh asan).
# Env: OUT (build dir, as run.sh), VERBOSE=n (print n lines of each log).
W="$(cd "$(dirname "$0")" && pwd)"
OUT="${OUT:-${SUITE_OUT:-${SPINE_TEST_OUT:?SPINE_TEST_OUT must name the build output directory}/lifecycle}}"
run() { local t=$1; shift; local out; out=$(OUT=$OUT "$W/run.sh" "$W/$t" "$@" 2>&1); local rc=$?
  local verdict="ok"
  if grep -q "AddressSanitizer\|UndefinedBehaviorSanitizer\|runtime error" <<<"$out"; then verdict=$(grep -m1 -o "AddressSanitizer: [a-z-]*\|UndefinedBehaviorSanitizer\|runtime error: [a-z ]*" <<<"$out"); 
  elif grep -q "LUA ERROR" <<<"$out"; then verdict="LUA ERROR: $(grep -m1 'LUA ERROR' <<<"$out" | sed 's/.*lua:[0-9]*: //' | cut -c1-90)"; fi
  printf "%-34s %-22s -> %s\n" "$t" "$*" "$verdict"
  if [[ -n "${VERBOSE:-}" ]]; then grep -v "^    #\|^  0x\|^=>\|Shadow\|^Addressable\|^Partially\|^Heap\|^Freed\|^Stack\|^Global\|^Poison\|^Container\|^Array\|^Intra\|^ASan\|^Left\|^Right\|^Internal\|host\]\|plugin v1" <<<"$out" | head -${VERBOSE} | sed 's/^/      | /'; fi
}
while read -r script args; do
  [[ -z "$script" || "$script" == \#* ]] && continue
  run "$script" $args
done <"$W/scenarios"
