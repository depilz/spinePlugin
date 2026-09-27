#!/bin/bash
# api: the plugin's Lua surface on the line against 1.5.0's (a27bde4: its bindings equal tag 1.5.0's). surface.py
# extracts it statically from the bindings preprocessed for the line (SPINE_43() resolved): module functions,
# every registry metatable's keys, and the properties its __index/__newindex compare with strcmp, which no
# runtime walk can see. The baseline is the same extraction on a27bde4's shared/ (git archive). One test per
# owner (module or registry name) on either side, PASS iff its rows are the same; a failing test's log is the diff.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
source "$W/../host/host.sh"
BASELINE=a27bde4

# extract name shared_dir include...: the surface of shared_dir's bindings as $SUITE_OUT/<name>.tsv
extract() {
  local name=$1 shared=$2 f
  shift 2
  mkdir -p "$SUITE_OUT/$name"
  for f in "$shared"/*.cpp; do
    clang++ -std=c++17 -E "$@" "$f" -o "$SUITE_OUT/$name/$(basename "$f").i"
  done
  python3 "$W/surface.py" "$shared" "$SUITE_OUT/$name"/*.i >"$SUITE_OUT/$name.tsv"
}

rm -rf "$SUITE_OUT/base" && mkdir -p "$SUITE_OUT/base"
git -C "$SPINE_REPO" archive "$BASELINE" shared | tar -x -C "$SUITE_OUT/base"
extract baseline "$SUITE_OUT/base/shared" -I"$LUA51_SRC" -I"$SUITE_OUT/base/shared" -I"$SUITE_OUT/base/shared/spine" \
  -I"$CORONA_NATIVE/Corona/shared/include/Corona"
extract line "$SPINE_REPO/shared" "${HOST_INC[@]}"

# same owner: the owner's rows are the same in both surfaces (the log shows the diff)
same() {
  diff <(awk -F'\t' -v o="$1" '$1 == o' "$SUITE_OUT/baseline.tsv") \
    <(awk -F'\t' -v o="$1" '$1 == o' "$SUITE_OUT/line.tsv")
}
# kinds tsv: every kind of row is there, so a broken extraction cannot pass as an empty diff
kinds() { [[ "$(cut -f2 "$1" | sort -u | tr '\n' ' ')" == "field function get set " ]]; }

run_test "extracted $BASELINE" kinds "$SUITE_OUT/baseline.tsv"
run_test "extracted line" kinds "$SUITE_OUT/line.tsv"
cut -f1 "$SUITE_OUT/baseline.tsv" "$SUITE_OUT/line.tsv" | sort -u | while IFS= read -r owner; do
  run_test "surface $owner" same "$owner"
done
