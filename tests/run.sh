#!/bin/bash
# Runs the test suites on each runtime line: tests/run.sh [--list] [--line <runtime>] [suite...]. The lines are
# the runtimes under runtime/spine-<runtime>; --line runs one of them. With no suite it runs every suite not marked
# named-only (see tests/lib.sh for the suite contract), on every line the suite runs on (ONLY_42). A line passes iff
# every failing test is listed in tests/xfail/<runtime>.tsv and no listed test passes (XPASS) or goes unreported
# (STALE), and its test ids match tests/manifest/<runtime>.tsv for the suites it ran: no listed id missing (MISSING,
# unless the row is marked optional), no unlisted id (UNLISTED) and no suite or line without a row (EMPTY). The run
# passes iff every line that ran a suite does, and at least one line did.
# Environment (all optional): SPINE_REPO, SPINE_TEST_OUT, SDKROOT, LUA51_SRC, CORONA_NATIVE;
# SOLAR2D_SIM_APP for the sim suite.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SUPPORTED_SDKS="26.4"
XCODE_SDK_EXAMPLE="/Applications/Xcode_26.4.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk"
# Suites that run on the 4.2 line only: gate (checks the tracked archives, not a line), guard (checks the history
# of both lines at once) and docs (builds the one docs tree for each plugin line).
ONLY_42="gate guard docs"
# Suites that read SPINE_REPO's git history, so they need it to be a git checkout (not a git archive export)
GIT_SUITES="api gate guard sim"
# flat_spines, line_spines and spines_check
source "$TESTS_DIR/host/spines.sh"

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

# check_checkout suite...: dies when a selected suite needs git and SPINE_REPO is not the top of a git checkout (a
# worktree's .git is a file, and an export nested in another checkout has a .git above it)
check_checkout() {
  local s need="" top
  for s; do [[ " $GIT_SUITES " == *" $s "* ]] && need="$need $s"; done
  [[ -n "$need" ]] || return 0
  top=$(git -C "$SPINE_REPO" rev-parse --show-toplevel 2>/dev/null) &&
    [[ "$(physical_path "$top")" == "$(physical_path "$SPINE_REPO")" ]] ||
    die "SPINE_REPO=$SPINE_REPO needs a git checkout for the suites$need (not a git archive export); run from a clone or name only other suites"
}

# runtime_lines: the SPINE_VERSION_STRING of every runtime/spine-*/spine/Version.h, one per line
runtime_lines() {
  local v
  for v in "$SPINE_REPO"/runtime/spine-*/spine/Version.h; do
    sed -n 's/^#define SPINE_VERSION_STRING "\(.*\)"$/\1/p' "$v"
  done
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

manifest_file() {
  local file
  file="$TESTS_DIR/manifest/$SPINE_RUNTIME.tsv"
  [[ -f "$file" ]] || die "no manifest $file for runtime '$SPINE_RUNTIME'"
  echo "$file"
}

# line_suites: the registered suites that run on $SPINE_RUNTIME
line_suites() {
  local s
  for s in $(suites); do [[ "$SPINE_RUNTIME" != 4.2 && " $ONLY_42 " == *" $s "* ]] || echo "$s"; done
}

# verdict xfail_file manifest_file ran_suites [results_file]: without results only validates the two lists
verdict() {
  awk -F'\t' -v registered=" $(suites | tr '\n' ' ') " -v online=" $(line_suites | tr '\n' ' ') " -v ran=" $3 " \
    -v out="$SPINE_TEST_OUT" -v line="$SPINE_RUNTIME" '
    function listed(s) { return index(ran, " " s " ") }
    FILENAME == ARGV[2] {
      if ($0 ~ /^#/ || $0 == "" || ($1 == "suite" && $2 == "test")) next
      id = $1 SUBSEP $2
      if (NF < 2 || NF > 3 || $2 == "" || (NF == 3 && $3 != "optional"))
        mproblem = mproblem sprintf("line %d: needs suite, test and optionally \"optional\"\n", FNR)
      else if (!index(online, " " $1 " ")) mproblem = mproblem sprintf("line %d: suite %s does not run on %s\n", FNR, $1, line)
      else if (id in expect) mproblem = mproblem sprintf("line %d: duplicate %s %s\n", FNR, $1, $2)
      expect[id] = 1; optional[id] = $3 == "optional"; msuite[id] = $1; mtest[id] = $2
      next
    }
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
      if ($3 == "_harness") next
      rows[$1]++; total++
      if (!(id in expect)) { print "UNLISTED", $1, $3; failed++ }
    }
    END {
      for (id in key) if (!(id in expect)) problem = problem sprintf("%s %s is not in %s\n", suite[id], test[id], ARGV[2])
      if (problem != "") { printf "run.sh: bad xfail list %s\n%s", ARGV[1], problem > "/dev/stderr"; exit 2 }
      if (mproblem != "") { printf "run.sh: bad manifest %s\n%s", ARGV[2], mproblem > "/dev/stderr"; exit 2 }
      if (ARGC < 4) exit 0
      for (id in expect) if (listed(msuite[id]) && !(id in seen) && !optional[id]) {
        if (id in key) print "STALE", msuite[id], mtest[id], key[id]
        else print "MISSING", msuite[id], mtest[id]
        failed++
      }
      n = split(ran, names, " ")
      for (i = 1; i <= n; i++) if (!rows[names[i]]) { print "EMPTY", names[i]; failed++ }
      if (!total) { print "EMPTY", "line " line; failed++ }
      printf "%s: %d passed, %d xfail, %d failed\n", line, passed, xfailed, failed
      exit failed > 0
    }' "$1" "$2" ${4:+"$4"}
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

# run_line runtime suite...: runs the suites that run on the line, with SPINE_RUNTIME, SPINE_SPINES (checked to be
# the line's exports) and a SPINE_TEST_OUT of its own, and verdicts them against the line's xfail list and manifest;
# returns 3 when no suite runs on the line
run_line() {
  local s results xfail manifest ran=()
  export SPINE_RUNTIME=$1 SPINE_TEST_OUT=$ROOT_OUT/$1
  shift
  mkdir -p "$SPINE_TEST_OUT"
  SPINE_SPINES=$(line_spines "$SPINE_RUNTIME") || return 1
  export SPINE_SPINES
  spines_check || return 1
  echo "=== runtime $SPINE_RUNTIME ($SPINE_TEST_OUT)"
  results="$SPINE_TEST_OUT/results.tsv"
  : >"$results"
  for s; do
    if [[ "$SPINE_RUNTIME" != 4.2 && " $ONLY_42 " == *" $s "* ]]; then echo "== $s: 4.2 only"; continue; fi
    ran+=("$s")
    run_suite "$s"
    cat "$SPINE_TEST_OUT/$s/results.tsv" >>"$results"
  done
  if (( ! ${#ran[@]} )); then echo "$SPINE_RUNTIME: no selected suite runs on this line"; return 3; fi
  xfail=$(xfail_file)
  manifest=$(manifest_file)
  verdict "$xfail" "$manifest" "${ran[*]}" "$results"
}

main() {
  local line="" registered lines xfail manifest s rc=0 any=0 selected=()
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
  check_checkout ${selected[@]+"${selected[@]}"}
  resolve_test_out
  for line in $lines; do
    xfail=$(SPINE_RUNTIME=$line xfail_file)
    manifest=$(SPINE_RUNTIME=$line manifest_file)
    SPINE_RUNTIME=$line verdict "$xfail" "$manifest" ""
  done
  for line in $lines; do
    run_line "$line" ${selected[@]+"${selected[@]}"} || case $? in 3) continue ;; *) rc=1 ;; esac
    any=1
  done
  (( any )) || { echo "run.sh: no selected suite runs on any selected line" >&2; return 1; }
  return $rc
}

main "$@"
