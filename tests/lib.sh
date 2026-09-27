# Sourced by tests/<suite>/suite.sh. tests/run.sh finds every tests/*/suite.sh and runs it with bash; a line
# "# run.sh: named-only" in it keeps the suite out of the default run. run.sh exports SPINE_REPO,
# SPINE_SPINES, SPINE_TEST_OUT, SDKROOT, LUA51_SRC, CORONA_NATIVE, SPINE_RUNTIME, TMPDIR and, per suite,
# SPINE_SUITE, SUITE_OUT (its build and log dir) and SUITE_RESULTS.
# run.sh runs a suite once per runtime line: SPINE_RUNTIME names the line (tests/host/host.sh builds against
# runtime/spine-$SPINE_RUNTIME), SPINE_SPINES is the line's example exports in the flat name/name.* layout and
# SPINE_TEST_OUT is the line's own. A suite never names a line; a line-specific test source sits next to its
# base as name43.cpp (host_line_src).
# A suite records one row per test id with record or run_test and exits 0 once it has run; a non-zero exit
# or no rows fails it as test _harness. Test ids (no tabs) are what tests/xfail/<runtime>.tsv lists.

export ASAN_OPTIONS="${ASAN_OPTIONS:-detect_leaks=0:abort_on_error=0}"

# record PASS|FAIL test
record() { printf '%s\t%s\t%s\n' "$SPINE_SUITE" "$1" "$2" >>"$SUITE_RESULTS"; }

# sanitizer_clean log: UBSan keeps running after a report, so a zero exit is not enough
sanitizer_clean() { ! grep -qE 'ERROR: (Address|Leak)Sanitizer|runtime error:' "$1"; }

# run_test test command...: PASS when the command exits 0 with a sanitizer-clean log in $SUITE_OUT/logs
run_test() {
  local test=$1 log
  shift
  log="$SUITE_OUT/logs/$(printf '%s' "$test" | tr '/ ' '__').log"
  if "$@" >"$log" 2>&1 && sanitizer_clean "$log"; then record PASS "$test"; else record FAIL "$test"; fi
}
