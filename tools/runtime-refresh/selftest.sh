#!/bin/bash
# Self-test of refresh.sh on a throwaway upstream repo, once per upstream layout (4.2's spine-cpp/spine-cpp, 4.3's
# spine-cpp): a license-comment conflict takes upstream's text, a code conflict keeps its markers and exits 1 (also in a
# file without a license comment), clean changes on both sides merge, plugin-only and upstream-deleted files are kept,
# new upstream files are added, --out leaves the runtime dir alone, a refresh without code conflicts exits 0, and a
# wrong --cpp is a usage error.
# usage: tools/runtime-refresh/selftest.sh
# Prints OK|FAIL per check; exit 0 = every check passed, 1 = a check failed.
set -uo pipefail

REFRESH="$(cd "$(dirname "$0")" && pwd)/refresh.sh"
T=$(mktemp -d "${TMPDIR:-/tmp}/runtime-refresh-selftest.XXXXXX") || exit 1
trap 'rm -rf "$T"' EXIT
ok=1

# check what command...: OK or FAIL for the command's exit status
check() {
  local what=$1
  shift
  if "$@" >/dev/null 2>&1; then echo "OK   $what"; else echo "FAIL $what"; ok=0; fi
}

# licensed license lines...: a license comment naming the license, then the lines
licensed() { printf '/*\n * License %s\n */\n' "$1"; shift; printf '%s\n' "$@"; }

git_() { git -C "$T/up" -c user.name=selftest -c user.email=selftest@invalid -c commit.gpgsign=false \
  -c core.hooksPath=/dev/null "$@"; }

# upstream cpp: a repo with a base commit and a new commit under <cpp>/{include,src}/spine; prints nothing
upstream() {
  local inc="$T/up/$1/include/spine" src="$T/up/$1/src/spine"
  rm -rf "$T/up"
  mkdir -p "$inc" "$src"
  git_ init -q
  licensed 2023 a1 a2 a3 a4 a5 >"$inc/A.h"
  licensed 2023 b1 b2 b3 >"$src/B.cpp"
  licensed 2023 g >"$src/Gone.cpp"
  printf '%s\n' n1 n2 n3 >"$src/NoLicense.cpp"
  git_ add -A && git_ commit -qm base && git_ tag base
  licensed 2025 a1-up a2 a3 a4 a5 >"$inc/A.h"
  licensed 2023 b1 b2-up b3 >"$src/B.cpp"
  git_ rm -q "$src/Gone.cpp"
  licensed 2025 n >"$src/New.cpp"
  printf '%s\n' n1 n2-up n3 >"$src/NoLicense.cpp"
  git_ add -A && git_ commit -qm new && git_ tag new
}

# vendored b2 [n2]: the runtime dir at base with plugin changes, B.cpp's b2 line and NoLicense.cpp's n2 line as given
vendored() {
  rm -rf "$T/rt" "$T/out"
  mkdir -p "$T/rt"
  licensed "2023 plugin" a1 a2 a3 a4 a5-plugin >"$T/rt/A.h"
  licensed 2023 b1 "$1" b3 >"$T/rt/B.cpp"
  licensed 2023 g >"$T/rt/Gone.cpp"
  licensed plugin l >"$T/rt/Local.cpp"
  printf '%s\n' n1 "${2:-n2}" n3 >"$T/rt/NoLicense.cpp"
}

same() { cmp -s "$1" <(shift; licensed "$@"); }
report_has() { grep -qE "$1" "$T/report"; }
report_lacks() { ! report_has "$@"; }

for cpp in spine-cpp/spine-cpp spine-cpp; do
  upstream "$cpp"
  vendored b2-plugin n2-plugin
  rc=0
  "$REFRESH" --cpp "$cpp" --out "$T/out" "$T/up" base new "$T/rt" >"$T/report" 2>&1 || rc=$?
  check "$cpp: code conflict exits 1" test "$rc" -eq 1
  check "$cpp: license conflict takes upstream's text, clean changes merge" same "$T/out/A.h" 2025 a1-up a2 a3 a4 a5-plugin
  check "$cpp: license conflict is reported" report_has '^LICENSE A\.h:'
  check "$cpp: code conflict keeps its markers" grep -qx '<<<<<<< vendored' "$T/out/B.cpp"
  check "$cpp: code conflict is reported with its lines" report_has '^CONFLICT B\.cpp lines [0-9]+-[0-9]+$'
  check "$cpp: conflict in a file without a license comment keeps its markers" \
    grep -qx '<<<<<<< vendored' "$T/out/NoLicense.cpp"
  check "$cpp: a file without a license comment splits without errors" report_lacks '^head:'
  check "$cpp: upstream deletion is kept and warned" test -f "$T/out/Gone.cpp" -a -n "$(grep '^WARN Gone\.cpp:' "$T/report")"
  check "$cpp: plugin-only file is kept" same "$T/out/Local.cpp" plugin l
  check "$cpp: new upstream file is added" same "$T/out/New.cpp" 2025 n
  check "$cpp: --out leaves the runtime dir alone" same "$T/rt/B.cpp" 2023 b1 b2-plugin b3

  vendored b2
  rc=0
  "$REFRESH" --cpp "$cpp" "$T/up" base new "$T/rt" >"$T/report" 2>&1 || rc=$?
  check "$cpp: in place, no code conflict exits 0" test "$rc" -eq 0
  check "$cpp: in place, upstream change merges" same "$T/rt/B.cpp" 2023 b1 b2-up b3
done

rc=0
"$REFRESH" --cpp nowhere "$T/up" base new "$T/rt" >/dev/null 2>&1 || rc=$?
check "wrong --cpp is a usage error" test "$rc" -eq 2
check "--help prints the usage" grep -q '^usage: tools/runtime-refresh/refresh.sh' <("$REFRESH" --help)
(( ok ))
