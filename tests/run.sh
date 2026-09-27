#!/bin/bash
# Runs the test suites on each runtime line: tests/run.sh [--list] [--line <runtime>] [suite...]. The lines are
# the runtimes under runtime/spine-<runtime>; --line runs one of them. With no suite it runs every suite not marked
# named-only (see tests/lib.sh for the suite contract), on every line the suite runs on (ONLY_42). A line passes iff
# every failing test is listed in tests/xfail/<runtime>.tsv and no listed test passes (XPASS) or goes unreported
# (STALE); the run passes iff every line does.
# Environment (all optional): SPINE_REPO, SPINE_TEST_OUT, SDKROOT, LUA51_SRC, CORONA_NATIVE;
# SOLAR2D_SIM_APP for the sim suite.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SUPPORTED_SDKS="26.4"
XCODE_SDK_EXAMPLE="/Applications/Xcode_26.4.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk"
# Suites that run on the 4.2 line only: sim (4.2 until plugin.spine43 has a Simulator build), gate (checks the
# tracked archives, not a line) and guard (checks the history of both lines at once).
ONLY_42="gate guard sim"

die() { echo "run.sh: $*" >&2; exit 2; }

suites() {
  local s
  for s in "$TESTS_DIR"/*/suite.sh; do [[ -f "$s" ]] && basename "$(dirname "$s")"; done
}

default_suites() {
  local s
  for s in $(suites); do grep -qx '# run.sh: named-only' "$TESTS_DIR/$s/suite.sh" || echo "$s"; done
}

# physical_path path: path with symlinks resolved, also when its tail does not exist yet
physical_path() {
  local dir=${1%/} rest=""
  until [[ -d "$dir" ]]; do rest="/${dir##*/}$rest"; dir=$(dirname "$dir"); done
  [[ "$rest/" != *"/../"* ]] || die "'$1' has '..' in a part that does not exist yet"
  echo "$(cd "$dir" && pwd -P)$rest"
}

under() { [[ "$1" == "$2" || "$1" == "$2"/* ]]; }

set_env_defaults() {
  export SPINE_REPO="${SPINE_REPO:-$(cd "$TESTS_DIR/.." && pwd)}"
  export LUA51_SRC="${LUA51_SRC:-$TESTS_DIR/third_party/lua-5.1.3/src}"
  export CORONA_NATIVE="${CORONA_NATIVE:-$TESTS_DIR/third_party/solar2d}"
}

# runtime_lines: the SPINE_VERSION_STRING of every runtime/spine-*/spine/Version.h, one per line
runtime_lines() {
  local v
  for v in "$SPINE_REPO"/runtime/spine-*/spine/Version.h; do
    sed -n 's/^#define SPINE_VERSION_STRING "\(.*\)"$/\1/p' "$v"
  done
}

# flat_spines src view: links an export tree in the 4.3 layout (folder/export/name[-pro|-ess].*) into the 4.2 flat
# layout (view/name/name.*) and prints view. name.skel and name.json are the plain export, else -pro, else -ess
# (Corona43/Spine.lua's order); name.atlas falls back to the folder's atlas (sack lives in 7-anticipation).
flat_spines() {
  local src=$1 view=$2 export folder f name dir ext cand
  rm -rf "$view"
  for export in "$src"/*/export; do
    folder=${export%/export}; folder=${folder##*/}
    for f in "$export"/*.skel "$export"/*.json; do
      [[ -e "$f" ]] || continue
      name=${f##*/}; name=${name%.*}; name=${name%-pro}; name=${name%-ess}
      dir="$view/$name"
      [[ -d "$dir" ]] && continue
      mkdir -p "$dir"
      ln -s "$export"/* "$dir/"
      for ext in atlas skel json; do
        for cand in "$name.$ext" "$name-pro.$ext" "$name-ess.$ext" "$folder.$ext"; do
          [[ -e "$dir/$cand" ]] || continue
          [[ "$cand" == "$name.$ext" ]] || ln -s "$cand" "$dir/$name.$ext"
          break
        done
      done
    done
  done
  echo "$view"
}

# line_spines runtime: the line's example exports in the 4.2 flat layout, the suites' cwd (SPINE_SPINES)
line_spines() {
  case "$1" in
    4.2) echo "$SPINE_REPO/Corona/spines" ;;
    *) flat_spines "$SPINE_REPO/Corona${1//./}/spines" "$SPINE_TEST_OUT/spines" ;;
  esac
}

resolve_sdk() {
  local sdk=${SDKROOT:-$(xcrun --show-sdk-path 2>/dev/null || true)} version
  local hint="supported: MacOSX$SUPPORTED_SDKS.sdk; set SDKROOT to it, e.g. SDKROOT=$XCODE_SDK_EXAMPLE tests/run.sh"
  version=$(plutil -extract Version raw "$sdk/SDKSettings.plist" 2>/dev/null) || die "no macOS SDK at '$sdk' ($hint)"
  case " $SUPPORTED_SDKS " in
    *" $version "*) export SDKROOT=$sdk ;;
    *) die "unsupported macOS SDK MacOSX$version.sdk at $sdk ($hint)" ;;
  esac
}

resolve_test_out() {
  [[ -n "${SPINE_TEST_OUT:-}" ]] || SPINE_TEST_OUT=$(mktemp -d "${TMPDIR:-/tmp}/spine-tests.XXXXXX")
  local out repo
  out=$(physical_path "$SPINE_TEST_OUT")
  for repo in "$SPINE_REPO" "$TESTS_DIR/.."; do
    under "$out" "$(physical_path "$repo")" && die "SPINE_TEST_OUT=$SPINE_TEST_OUT is inside the repo ($out); choose a directory outside it"
  done
  under "$out" "$(physical_path "${HOME:?}/Library")" && die "SPINE_TEST_OUT=$SPINE_TEST_OUT is under ~/Library ($out); choose a directory outside it"
  mkdir -p "$out/tmp"
  export SPINE_TEST_OUT=$out TMPDIR=$out/tmp
  ROOT_OUT=$out
}

xfail_file() {
  local file
  file="$TESTS_DIR/xfail/$SPINE_RUNTIME.tsv"
  [[ -f "$file" ]] || die "no xfail list $file for runtime '$SPINE_RUNTIME'"
  echo "$file"
}

# verdict xfail_file ran_suites [results_file]: without results only validates the xfail list
verdict() {
  awk -F'\t' -v registered=" $(suites | tr '\n' ' ') " -v ran=" $2 " -v out="$SPINE_TEST_OUT" -v line="$SPINE_RUNTIME" '
    function listed(s) { return index(ran, " " s " ") }
    FILENAME == ARGV[1] {
      if ($0 ~ /^#/ || $0 == "" || ($1 == "suite" && $2 == "test")) next
      id = $1 SUBSEP $2
      if (NF < 4 || $2 == "" || $3 == "" || ($4 != "defect" && $4 != "pending-api"))
        problem = problem sprintf("line %d: needs suite, test, key, kind (defect|pending-api)\n", FNR)
      else if (!index(registered, " " $1 " ")) problem = problem sprintf("line %d: unknown suite %s\n", FNR, $1)
      else if (id in key) problem = problem sprintf("line %d: duplicate %s %s\n", FNR, $1, $2)
      key[id] = $3; suite[id] = $1; test[id] = $2
      next
    }
    {
      id = $1 SUBSEP $3; seen[id] = 1
      if ($2 == "PASS" && (id in key)) { print "XPASS", $1, $3, key[id]; failed++ }
      else if ($2 == "PASS") { print "PASS ", $1, $3; passed++ }
      else if (id in key) { print "XFAIL", $1, $3, key[id]; xfailed++ }
      else { print "FAIL ", $1, $3, "(logs: " out "/" $1 ")"; failed++ }
    }
    END {
      if (problem != "") { printf "run.sh: bad xfail list %s\n%s", ARGV[1], problem > "/dev/stderr"; exit 2 }
      if (ARGC < 3) exit 0
      for (id in key) if (listed(suite[id]) && !(id in seen)) { print "STALE", suite[id], test[id], key[id]; failed++ }
      printf "%s: %d passed, %d xfail, %d failed\n", line, passed, xfailed, failed
      exit failed > 0
    }' "$1" ${3:+"$3"}
}

# run_suite name: runs tests/<name>/suite.sh, adding a _harness failure when it exits non-zero or records nothing
run_suite() {
  local suite=$1 out="$SPINE_TEST_OUT/$1"
  rm -rf "$out/logs" "$out/results.tsv"
  mkdir -p "$out/logs"
  echo "== $suite ($out)"
  SPINE_SUITE=$suite SUITE_OUT=$out SUITE_RESULTS=$out/results.tsv \
    /bin/bash "$TESTS_DIR/$suite/suite.sh" >"$out/suite.log" 2>&1 && [[ -s "$out/results.tsv" ]] ||
    printf '%s\tFAIL\t_harness\n' "$suite" >>"$out/results.tsv"
}

# run_line runtime suite...: runs the suites that run on the line, with SPINE_RUNTIME, SPINE_SPINES and a
# SPINE_TEST_OUT of its own, and verdicts them against the line's xfail list
run_line() {
  local s results xfail ran=()
  export SPINE_RUNTIME=$1 SPINE_TEST_OUT=$ROOT_OUT/$1
  shift
  mkdir -p "$SPINE_TEST_OUT"
  SPINE_SPINES=$(line_spines "$SPINE_RUNTIME") || return 1
  export SPINE_SPINES
  echo "=== runtime $SPINE_RUNTIME ($SPINE_TEST_OUT)"
  results="$SPINE_TEST_OUT/results.tsv"
  : >"$results"
  for s; do
    if [[ "$SPINE_RUNTIME" != 4.2 && " $ONLY_42 " == *" $s "* ]]; then echo "== $s: 4.2 only"; continue; fi
    ran+=("$s")
    run_suite "$s"
    cat "$SPINE_TEST_OUT/$s/results.tsv" >>"$results"
  done
  xfail=$(xfail_file)
  verdict "$xfail" "${ran[*]-}" "$results"
}

main() {
  local line="" registered lines xfail s rc=0 selected=()
  case "${1:-}" in
    --list) suites; return ;;
    -h|--help) echo "usage: tests/run.sh [--list] [--line <runtime>] [suite...]"; return ;;
    --line) line=${2:-}; shift 2 || die "--line needs a runtime" ;;
  esac
  registered=$(suites)
  for s in "$@"; do grep -qxF -- "$s" <<<"$registered" || die "unknown suite '$s' (tests/run.sh --list names them)"; done
  if (( $# )); then selected=("$@"); else while IFS= read -r s; do selected+=("$s"); done < <(default_suites); fi
  set_env_defaults
  lines=$(runtime_lines)
  if [[ -n "$line" ]]; then
    grep -qxF -- "$line" <<<"$lines" || die "unknown runtime '$line' (runtimes: $(echo $lines))"
    lines=$line
  fi
  resolve_sdk
  resolve_test_out
  for line in $lines; do xfail=$(SPINE_RUNTIME=$line xfail_file); SPINE_RUNTIME=$line verdict "$xfail" ""; done
  for line in $lines; do run_line "$line" ${selected[@]+"${selected[@]}"} || rc=1; done
  return $rc
}

main "$@"
