#!/bin/bash
# api: the plugin's Lua surface on the line against 1.5.0's (a27bde4: its bindings equal tag 1.5.0's). surface.py
# extracts it statically from the bindings preprocessed for the line (SPINE_43() resolved): module functions,
# every registry metatable's keys, and the properties its __index/__newindex compare with strcmp, which no
# runtime walk can see. The baseline is the same extraction on a27bde4's shared/ (git archive), changed by the line's
# expected-diff (expected-diff/<runtime>.tsv): the surface's intended changes, one `line owner kind key +|-` row per
# key. One test per owner (module or registry name) on either side or in the expected-diff, PASS iff the line's rows
# are the baseline's with exactly the owner's listed changes; a failing test's log is the diff. A checkout without
# a27bde4 (a public clone) skips every test.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
source "$W/../host/host.sh"
BASELINE=a27bde4
DIFF="$W/expected-diff/$SPINE_RUNTIME.tsv"

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

if ! git -C "$SPINE_REPO" rev-parse -q --verify "$BASELINE^{commit}" >/dev/null; then
  skip '*' "needs the private baseline $BASELINE"
  exit 0
fi
rm -rf "$SUITE_OUT/base" && mkdir -p "$SUITE_OUT/base"
git -C "$SPINE_REPO" archive "$BASELINE" shared | tar -x -C "$SUITE_OUT/base"
extract baseline "$SUITE_OUT/base/shared" -I"$LUA51_SRC" -I"$SUITE_OUT/base/shared" -I"$SUITE_OUT/base/shared/spine" \
  -I"$CORONA_NATIVE/Corona/shared/include/Corona"
extract line "$SPINE_REPO/shared" "${HOST_INC[@]}"

# rows: the expected-diff's rows, its comments and header dropped
rows() { grep -v '^#' "$DIFF" | tail -n +2; }

# listed: every expected-diff row is `line owner kind key +|-` for this line and no key is listed twice
listed() {
  awk -F'\t' -v line="$SPINE_RUNTIME" '
    NF != 5 || $1 != line || $3 !~ /^(field|function|get|set)$/ || $5 !~ /^[+-]$/ { print "malformed: " $0; bad = 1 }
    seen[$2 FS $3 FS $4]++ { print "listed twice: " $0; bad = 1 }
    END { exit bad }' <(rows)
}

# expected owner: the owner's baseline rows with its listed changes applied. A listed change the baseline makes
# impossible (+ of a key it has, - of a key it lacks) is reported and fails, so every listed row must be observed.
expected() {
  awk -F'\t' -v OFS='\t' -v o="$1" -v base_name="$BASELINE" '
    FILENAME == ARGV[1] { if ($2 == o) change[$2 OFS $3 OFS $4] = $5; next }
    $1 == o { base[$0] = 1; if (!($0 in change)) print }
    END {
      for (r in change) {
        if (change[r] == "+" && !(r in base)) print r
        else if (change[r] == "+") { print "listed + of a key " base_name " has: " r > "/dev/stderr"; bad = 1 }
        else if (!(r in base)) { print "listed - of a key " base_name " lacks: " r > "/dev/stderr"; bad = 1 }
      }
      exit bad
    }' <(rows) "$SUITE_OUT/baseline.tsv"
}

# same owner: the line's rows of owner are the expected ones (the log shows the diff)
same() {
  local ok=0
  mkdir -p "$SUITE_OUT/expected"
  expected "$1" | LC_ALL=C sort >"$SUITE_OUT/expected/$1.tsv" || ok=1
  diff "$SUITE_OUT/expected/$1.tsv" <(awk -F'\t' -v o="$1" '$1 == o' "$SUITE_OUT/line.tsv" | LC_ALL=C sort) &&
    return $ok
}
# kinds tsv: every kind of row is there, so a broken extraction cannot pass as an empty diff
kinds() { [[ "$(cut -f2 "$1" | sort -u | tr '\n' ' ')" == "field function get set " ]]; }

run_test "extracted $BASELINE" kinds "$SUITE_OUT/baseline.tsv"
run_test "extracted line" kinds "$SUITE_OUT/line.tsv"
run_test "expected-diff" listed
{ cut -f1 "$SUITE_OUT/baseline.tsv" "$SUITE_OUT/line.tsv"; rows | cut -f2; } | sort -u | while IFS= read -r owner; do
  run_test "surface $owner" same "$owner"
done
