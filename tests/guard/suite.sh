#!/bin/bash
# guard: tests/guard/runtime_guard.sh (D10) over SPINE_GUARD_RANGE (default origin/main..HEAD); that its counterpart map
# lists every file tracked under one runtime line only and nothing that is missing; and that it flags exactly the
# unmatched files of a synthetic history (a directory-level guard would pass its "cross" commit).
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
GUARD="$W/runtime_guard.sh"
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

run_test "counterparts.tsv lists every one-sided runtime file" check_map
run_test "selftest flags exactly the unmatched files" selftest
run_test "range $RANGE" "$GUARD" --repo "$SPINE_REPO" "$RANGE"
