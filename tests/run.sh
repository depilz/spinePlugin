#!/bin/bash
# Runs the test suites: tests/run.sh [--list] [suite...]. With no suite it runs every suite not marked
# named-only (see tests/lib.sh for the suite contract). The run passes iff every failing test is listed in
# tests/xfail/<runtime>.tsv and no listed test passes (XPASS) or goes unreported (STALE).
# Environment (all optional): SPINE_REPO, SPINE_SPINES, SPINE_TEST_OUT, SDKROOT, LUA51_SRC, CORONA_NATIVE;
# SOLAR2D_SIM_APP for the sim suite.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SUPPORTED_SDKS="26.4"
XCODE_SDK_EXAMPLE="/Applications/Xcode_26.4.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk"

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
  export SPINE_SPINES="${SPINE_SPINES:-$SPINE_REPO/Corona/spines}"
  export LUA51_SRC="${LUA51_SRC:-$TESTS_DIR/third_party/lua-5.1.3/src}"
  export CORONA_NATIVE="${CORONA_NATIVE:-$TESTS_DIR/third_party/solar2d}"
  export SPINE_RUNTIME=$(sed -n 's/^#define SPINE_VERSION_STRING "\(.*\)"$/\1/p' "$SPINE_REPO/shared/spine/Version.h")
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
}

xfail_file() {
  local file
  file="$TESTS_DIR/xfail/$SPINE_RUNTIME.tsv"
  [[ -f "$file" ]] || die "no xfail list $file for runtime '$SPINE_RUNTIME'"
  echo "$file"
}

# verdict xfail_file ran_suites [results_file]: without results only validates the xfail list
verdict() {
  awk -F'\t' -v registered=" $(suites | tr '\n' ' ') " -v ran=" $2 " -v out="$SPINE_TEST_OUT" '
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
      printf "%d passed, %d xfail, %d failed\n", passed, xfailed, failed
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

main() {
  case "${1:-}" in
    --list) suites; return ;;
    -h|--help) echo "usage: tests/run.sh [--list] [suite...]"; return ;;
  esac
  local registered s results xfail selected=()
  registered=$(suites)
  for s in "$@"; do grep -qxF -- "$s" <<<"$registered" || die "unknown suite '$s' (tests/run.sh --list names them)"; done
  if (( $# )); then selected=("$@"); else while IFS= read -r s; do selected+=("$s"); done < <(default_suites); fi
  set_env_defaults
  resolve_sdk
  resolve_test_out
  xfail=$(xfail_file)
  verdict "$xfail" ""
  results="$SPINE_TEST_OUT/results.tsv"
  : >"$results"
  for s in ${selected[@]+"${selected[@]}"}; do run_suite "$s"; cat "$SPINE_TEST_OUT/$s/results.tsv" >>"$results"; done
  verdict "$xfail" "${selected[*]-}" "$results"
}

main "$@"
