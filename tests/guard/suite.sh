#!/bin/bash
# guard: tests/guard/runtime_guard.sh (D10) over SPINE_GUARD_RANGE (default origin/main..HEAD; skipped when it is unset
# and the checkout has no origin/main); that its counterpart map lists every file tracked under one runtime line only
# and nothing that is missing; and that it flags exactly the unmatched files of a synthetic history (a directory-level
# guard would pass its "cross" commit); and that no two tracked paths differ only in case (they collide on a
# case-insensitive checkout). Also tools/runtime-refresh/selftest.sh passes, and fails against a broken refresh.sh.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
GUARD="$W/runtime_guard.sh"
REFRESH_DIR="$W/../../tools/runtime-refresh"
RANGE=${SPINE_GUARD_RANGE:-origin/main..HEAD}

# check_map: prints each one-sided runtime file the map lacks and each mapped file that is not tracked
check_map() {
  git -C "$SPINE_REPO" ls-files runtime | awk -F'\t' '
    FNR == NR {
      if ($0 ~ /^#/ || $0 == "") next
      if (!l1) { l1 = $1; l2 = $2; next }
      if ($1 != "-") listed[l1 "/" $1] = 1
      if ($2 != "-") listed[l2 "/" $2] = 1
      if ($1 != "-" && $2 == "-") lone[l1 "/" $1] = 1
      if ($2 != "-" && $1 == "-") lone[l2 "/" $2] = 1
      if ($1 != "-" && $2 != "-") paired[l1 "/" $1] = paired[l2 "/" $2] = 1
      next
    }
    match($0, "^runtime/spine-[^/]+/") { tracked[substr($0, 15, RLENGTH - 15) "/" substr($0, RLENGTH + 1)] = 1 }
    END {
      for (f in tracked) {
        line = substr(f, 1, index(f, "/") - 1); rel = substr(f, index(f, "/") + 1)
        other = line == l1 ? l2 : l1
        if (!((other "/" rel) in tracked) && !(f in lone) && !(f in paired)) { print "not in map: " f; bad = 1 }
      }
      for (f in listed) if (!(f in tracked)) { print "mapped but not tracked: " f; bad = 1 }
      exit bad
    }' "$W/counterparts.tsv" -
}

# selftest: runs the guard over a synthetic history and compares its FLAG lines, sha stripped, with the expected ones
selftest() {
  local repo="$SUITE_OUT/selftest" expected actual rc=0
  export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=guard GIT_AUTHOR_EMAIL=guard@test \
    GIT_COMMITTER_NAME=guard GIT_COMMITTER_EMAIL=guard@test
  rm -rf "$repo"
  git init -q -b main "$repo"
  mkdir -p "$repo/runtime/spine-4.2/spine" "$repo/runtime/spine-4.3/spine"
  touch "$repo"/runtime/spine-4.2/spine/{Slot.cpp,Vector.h,Log.h} "$repo"/runtime/spine-4.3/spine/{Slot.cpp,SlotPose.cpp,Array.h}
  git -C "$repo" add -A && git -C "$repo" commit -qm base && git -C "$repo" tag base
  edit() { local msg=$1 f; shift; for f; do echo "$msg" >>"$repo/runtime/spine-$f"; done; git -C "$repo" commit -qam "$msg"; }
  edit both 4.2/spine/Slot.cpp 4.3/spine/Slot.cpp
  edit pair 4.2/spine/Vector.h 4.3/spine/Array.h
  edit renamed 4.2/spine/Slot.cpp 4.3/spine/SlotPose.cpp
  edit cross 4.2/spine/Slot.cpp 4.3/spine/Array.h
  edit $'trailer\n\nRuntime-other: no 4.3 counterpart' 4.2/spine/Log.h
  edit lone 4.2/spine/Log.h
  git -C "$repo" checkout -qb side HEAD~1
  edit side 4.2/spine/Vector.h 4.3/spine/Array.h
  git -C "$repo" checkout -q main
  git -C "$repo" merge -q --no-ff --no-commit side
  echo merge >>"$repo/runtime/spine-4.3/spine/Slot.cpp"
  git -C "$repo" commit -qam "one-sided merge"
  expected="cross: runtime/spine-4.2/spine/Slot.cpp, counterpart unchanged: runtime/spine-4.3/spine/Slot.cpp runtime/spine-4.3/spine/SlotPose.cpp
cross: runtime/spine-4.3/spine/Array.h, counterpart unchanged: runtime/spine-4.2/spine/Vector.h
lone: runtime/spine-4.2/spine/Log.h, counterpart unchanged: none"
  actual=$("$GUARD" --repo "$repo" base..main) || rc=$?
  printf '%s\n' "$actual"
  (( rc == 1 )) && [[ "$(sed 's/^FLAG [0-9a-f]* //' <<<"$actual" | sort)" == "$expected" ]]
}

# commit rev: the commit rev names in SPINE_REPO, or "unresolved"
commit() { git -C "$SPINE_REPO" rev-parse -q --verify "$1^{commit}" || echo unresolved; }

# range_check: the guard over RANGE; the id stays "range" whatever SPINE_GUARD_RANGE is, the range and the commits
# it resolves to go to the log on stderr (a range base like origin/main differs between clones)
range_check() {
  local base=${RANGE%%..*} tip=${RANGE##*..}
  echo "range: $RANGE, base $(commit "${base:-HEAD}"), tip $(commit "${tip:-HEAD}")" >&2
  "$GUARD" --repo "$SPINE_REPO" "$RANGE"
}

# case_unique: reads paths on stdin and prints each group of paths that differ only in case; fails when there is one
case_unique() {
  local dups
  dups=$(LC_ALL=C sort -f | LC_ALL=C uniq -i -D) || return 2
  [[ -z "$dups" ]] || { printf 'paths that differ only in case:\n%s\n' "$dups"; return 1; }
}

case_check() { git -C "$SPINE_REPO" -c core.quotePath=off ls-files | case_unique; }

# case_firing: case_unique fails on a synthetic list with two paths that differ only in case, and names both
case_firing() {
  local out
  out=$(printf 'a/B.rst\na/c.rst\na/b.rst\n' | case_unique) && return 1
  echo "$out"
  grep -qx 'a/B.rst' <<<"$out" && grep -qx 'a/b.rst' <<<"$out" && ! grep -q 'a/c.rst' <<<"$out"
}

# refresh_mutant: selftest.sh, run beside a refresh.sh that keeps the vendored license comment on a license conflict,
# fails and names that check
refresh_mutant() {
  local dir="$SUITE_OUT/refresh-mutant" out
  rm -rf "$dir" && mkdir -p "$dir"
  cp "$REFRESH_DIR/selftest.sh" "$dir/"
  sed 's|cp "$T/new.lic" "$T/ours.lic"|:|' "$REFRESH_DIR/refresh.sh" >"$dir/refresh.sh"
  chmod +x "$dir/refresh.sh"
  ! cmp -s "$REFRESH_DIR/refresh.sh" "$dir/refresh.sh" || { echo "mutation not applied"; return 1; }
  out=$("$dir/selftest.sh") && { echo "$out"; return 1; }
  echo "$out"
  grep -q "^FAIL .*license conflict takes upstream's text" <<<"$out"
}

run_test "counterparts.tsv lists every one-sided runtime file" check_map
run_test "selftest flags exactly the unmatched files" selftest
if [[ -z ${SPINE_GUARD_RANGE:-} && $(commit origin/main) == unresolved ]]; then
  skip range "needs origin/main of the upstream clone"
else
  run_test "range" range_check
fi
run_test "case-insensitive-unique tracked paths" case_check
run_test "firing: two paths differing in case fail" case_firing
run_test "runtime-refresh selftest passes" "$REFRESH_DIR/selftest.sh"
run_test "firing: a refresh.sh keeping the vendored license comment fails the runtime-refresh selftest" refresh_mutant
