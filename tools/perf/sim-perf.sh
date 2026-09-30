#!/bin/bash
# Mac Simulator perf reference (evidence, not a test suite: no manifest rows). Runs one tests/sim scenario on several
# plugin builds of one line, in rounds that run every build once, round-robin, all under one held
# /tmp/spine-sim.lock, in the isolated Simulator copy of tests/sim/suite.sh (whose functions it sources):
#   tools/perf/sim-perf.sh <out> <rounds> <label>=shipped:<tag>|<label>=build:<rev>...
#     shipped:<tag>  plugin.spine, the plugin_spine.dylib of <tag>'s mac-sim archive (1.2.6, 1.5.0; 4.2 only), ad-hoc
#                    signed
#     build:<rev>    the line's plugin (plugin.spine42|43) built by xcodebuild from a git archive of <rev> (build_dylib)
# Each build has its own plugins dir holding only its plugin, and the project's build.settings names only that plugin.
# A run passes identity when its stdout carries exactly the build's load banner. At every "MARK <name>" line of the
# scenario's results the driver samples the Simulator's footprint (footprint -f bytes), then writes <name>.ack
# next to the results, which a scenario run with "sample" waits for (tests/sim/s6_perf.lua).
# Writes <out>/runs.tsv (label, round, identity PASS|FAIL, scenario PASS|FAIL) and per run
# <out>/raw/<label>-r<round>.log (the scenario's stdout and results) and .footprint; tools/perf/summary.py <out>
# reduces them, discarding round 1. Refuses to run on battery power.
# Environment: SDKROOT and SOLAR2D_SIM_APP as for tests/run.sh sim; SPINE_REPO (default: this checkout);
# SPINE_RUNTIME, the line (default 4.2);
# SCENARIO, a tests/sim script or a path to one (default s6_perf.lua); SCENARIO_ARG (default "<plugin> sample").
set -euo pipefail
TOOLS="$(cd "$(dirname "$0")" && pwd)"
die() { echo "sim-perf: $*" >&2; exit 2; }
(( $# >= 3 )) || die "usage: $0 <out> <rounds> <label>=shipped:<tag>|<label>=build:<rev>..."
OUT=$1 ROUNDS=$2
shift 2
: "${SDKROOT:?set SDKROOT as for tests/run.sh}"
pmset -g batt | grep -q "'AC Power'" || die "not on AC power"
LOCK=/tmp/spine-sim.lock
(set -o noclobber; echo $$ >"$LOCK") 2>/dev/null || die "$LOCK is held (pid $(cat "$LOCK" 2>/dev/null))"
trap 'rm -f "$LOCK"' EXIT
mkdir -p "$OUT/raw"
OUT=$(cd "$OUT" && pwd)
export SPINE_REPO=${SPINE_REPO:-$(cd "$TOOLS/../.." && pwd)} SPINE_RUNTIME=${SPINE_RUNTIME:-4.2}
export SPINE_TEST_OUT=$OUT/test-out SUITE_OUT=$OUT/sim SPINE_SUITE=sim-perf SUITE_RESULTS=$OUT/guard.tsv
source "$TOOLS/../../tests/host/spines.sh"
SPINE_SPINES=$(line_spines "$SPINE_RUNTIME")
export SPINE_SPINES
source "$TOOLS/../../tests/sim/suite.sh"
trap 'guard_user_plugins; rm -f "$LOCK"' EXIT
SCENARIO=${SCENARIO:-s6_perf.lua}
XCODEPROJ=mac/Plugin.xcodeproj
[[ "$SPINE_RUNTIME" == 4.2 ]] || XCODEPROJ=mac/Plugin${SPINE_RUNTIME//./}.xcodeproj

# sample_marks results raw: forever, per new "MARK <name>" line of results: the Simulator copy's footprint into raw,
# then <name>.ack beside results
sample_marks() {
  local seen=0 name pid
  while :; do
    while IFS=$'\t' read -r _ name _; do
      seen=$((seen + 1))
      pid=$(pgrep -f "^$APP/Contents/MacOS/" | head -1) || pid=
      printf 'MARK %s pid %s\n' "$name" "$pid" >>"$2"
      [[ -z "$pid" ]] || footprint -f bytes -p "$pid" >>"$2" 2>&1 || true
      : >"$(dirname "$1")/$name.ack"
    done < <(grep $'^MARK\t' "$1" 2>/dev/null | tail -n +$((seen + 1)))
    sleep 0.2
  done
}

make_app
setup_project
[[ "$SCENARIO" != */* ]] || cp "$SCENARIO" "$PROJECT/"
build=$(plutil -extract CFBundleVersion raw "$APP/Contents/Info.plist")
labels=() plugins=() banners=()
for v; do
  label=${v%%=*} src=${v#*=}
  dir=$OUT/plugins-$label
  rm -rf "$dir"
  mkdir -p "$dir"
  case "$src" in
    shipped:*)
      [[ "$SPINE_RUNTIME" == 4.2 ]] || die "variant '$v': shipped 1.x plugins are 4.2 builds"
      git -C "$SPINE_REPO" show "${src#shipped:}:plugin/com.studycat.spine/plugin.spine/mac-sim/data.tgz" |
        tar -xzf - -C "$dir" plugin_spine.dylib
      codesign -f -s - "$dir/plugin_spine.dylib"
      plugins+=(plugin.spine)
      banners+=("Solar2d Spine plugin v${src#shipped:} loaded with Spine 4.2.XX") ;;
    build:*)
      build_dylib "$XCODEPROJ" "plugin_spine${SPINE_RUNTIME//./}" "${src#build:}"
      cp "${DYLIBS[${#DYLIBS[@]} - 1]}" "$dir/"
      plugins+=("$PLUGIN")
      banners+=("$(line_banner "${src#build:}")") ;;
    *) die "variant '$v': want <label>=shipped:<tag> or <label>=build:<rev>" ;;
  esac
  printf '{"Version":3,"CoronaBuild":"%s","com.studycat/%s":{"lastUpdate":2100000000}}\n' \
    "$build" "${plugins[${#plugins[@]} - 1]}" >"$dir/catalog.json"
  labels+=("$label")
done

printf 'label\tround\tidentity\tscenario\n' >"$OUT/runs.tsv"
for ((round = 1; round <= ROUNDS; round++)); do
  for i in "${!labels[@]}"; do
    label=${labels[i]} PLUGINS=$OUT/plugins-${labels[i]}
    raw=$OUT/raw/$label-r$round
    test="$(basename "$SCENARIO" .lua) $label r$round"
    printf "settings =\n{\n    plugins =\n    {\n        ['%s'] = {publisherId = 'com.studycat'},\n    },\n}\n" \
      "${plugins[i]}" >"$PROJECT/build.settings"
    rm -f "$SUITE_OUT"/results/*.ack "$raw.footprint"
    sample_marks "$(result_file "$test")" "$raw.footprint" &
    sampler=$!
    ok=PASS
    scenario "$test" "${SCENARIO##*/}" "${SCENARIO_ARG:-${plugins[i]} sample}" >"$raw.log" 2>&1 || ok=FAIL
    kill "$sampler" 2>/dev/null || true
    wait "$sampler" 2>/dev/null || true
    id=FAIL
    [[ "$(grep '^Solar2d Spine plugin ' "$(stdout_file "$test")" || true)" == "${banners[i]}" ]] && id=PASS
    printf '%s\t%s\t%s\t%s\n' "$label" "$round" "$id" "$ok" | tee -a "$OUT/runs.tsv"
  done
done
