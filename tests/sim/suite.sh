#!/bin/bash
# run.sh: named-only
# sim: every scenario in ./scenarios in an isolated copy of the Solar2D Simulator ($SOLAR2D_SIM_APP), one Simulator
# process per scenario, with plugin_spine.dylib built by xcodebuild from a git archive of HEAD (so uncommitted
# changes are not in it). A scenario passes when it runs to "DONE exit 0" with no unhandled or logged error; its
# CHECK lines are recorded as "<test> <check>". Nothing is written to the user's Simulator Plugins dir or its
# preferences domain (the copy's own ...spinetests preferences and crash reports do land under ~/Library), and the
# suite fails if the user's Plugins/plugin_spine.dylib changes while it runs.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
: "${SOLAR2D_SIM_APP:?set SOLAR2D_SIM_APP to the Solar2D Simulator app, e.g. /Applications/Corona-3731/Corona Simulator.app}"

BUNDLE_ID=com.coronalabs.Corona_Simulator.spinetests
TIMEOUT_S=300
DEVELOPER_DIR=${DEVELOPER_DIR:-${SDKROOT%%/Platforms/*}}
CORONA_ROOT=$(dirname "$SOLAR2D_SIM_APP")/Native
SIM_HOME=$SUITE_OUT/home
APP="$SUITE_OUT/app/Corona Simulator.app"
PLUGINS=$SUITE_OUT/plugins
PROJECT=$SUITE_OUT/project

USER_HOME=$(dscl . -read "/Users/$(id -un)" NFSHomeDirectory | sed 's/^NFSHomeDirectory: //')
USER_DYLIB="$USER_HOME/Library/Application Support/Corona/Simulator/Plugins/plugin_spine.dylib"
user_dylib_mtime() { stat -f %m "$USER_DYLIB" 2>/dev/null || echo absent; }
USER_DYLIB_MTIME=$(user_dylib_mtime)
guard_user_dylib() {
  echo "user plugin_spine.dylib mtime before $USER_DYLIB_MTIME, after $(user_dylib_mtime)"
  if [[ "$(user_dylib_mtime)" == "$USER_DYLIB_MTIME" ]]; then record PASS "user Plugins/plugin_spine.dylib unchanged"
  else record FAIL "user Plugins/plugin_spine.dylib unchanged"; fi
}
trap guard_user_dylib EXIT

# build_dylib: $SUITE_OUT/dylib/<HEAD>/plugin_spine.dylib, ad-hoc signed. The mac project's "Copy to Simulator's
# Plugin Directory" phase is pointed at dylib/copied (and HOME at a fake home) before building.
build_dylib() {
  local head dir tree pbx
  head=$(git -C "$SPINE_REPO" rev-parse HEAD) || return 1
  dir=$SUITE_OUT/dylib/$head
  DYLIB=$dir/plugin_spine.dylib
  [[ -f "$DYLIB" ]] && return
  rm -rf "$SUITE_OUT/dylib"
  tree=$dir/tree
  pbx=$tree/mac/Plugin.xcodeproj/project.pbxproj
  mkdir -p "$tree" "$dir/copied" "$dir/home"
  git -C "$SPINE_REPO" archive HEAD | tar -x -C "$tree" || return 1
  sed -i '' 's#PLUGINS_DIR=\\"${HOME}/Library/Application Support/Corona/Simulator/Plugins\\"#PLUGINS_DIR=\\"'"$dir/copied"'\\"#' "$pbx"
  if grep -q 'Corona/Simulator/Plugins' "$pbx" || ! grep -qF "PLUGINS_DIR=\\\"$dir/copied\\\"" "$pbx"; then
    echo "sim: could not redirect the Copy to Simulator's Plugin Directory phase in $pbx" >&2
    return 1
  fi
  DEVELOPER_DIR=$DEVELOPER_DIR "$DEVELOPER_DIR/usr/bin/xcodebuild" -project "$tree/mac/Plugin.xcodeproj" \
    -scheme plugin_spine -configuration Release -derivedDataPath "$dir/dd" -destination 'generic/platform=macOS' \
    ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO HOME="$dir/home" CORONA_ROOT="$CORONA_ROOT" build \
    >"$dir/build.log" 2>&1 || { tail -30 "$dir/build.log" >&2; return 1; }
  # the copy phase runs before signing: take the DerivedData product and sign it
  cp "$dir/dd/Build/Products/Release/plugin_spine.dylib" "$DYLIB.unsigned"
  codesign -f -s - "$DYLIB.unsigned" && mv "$DYLIB.unsigned" "$DYLIB"
}

# make_app: a copy of $SOLAR2D_SIM_APP with its own bundle id, re-signed ad-hoc with the original entitlements
make_app() {
  local stamp
  stamp="$SOLAR2D_SIM_APP $(plutil -extract CFBundleVersion raw "$SOLAR2D_SIM_APP/Contents/Info.plist")" || return 1
  [[ -d "$APP" && "$(cat "$SUITE_OUT/app/stamp" 2>/dev/null)" == "$stamp" ]] && return
  rm -rf "$SUITE_OUT/app"
  mkdir -p "$SUITE_OUT/app"
  ditto "$SOLAR2D_SIM_APP" "$APP"
  plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$APP/Contents/Info.plist"
  codesign -d --entitlements - --xml "$SOLAR2D_SIM_APP" >"$SUITE_OUT/app/entitlements.plist"
  codesign -f -s - --entitlements "$SUITE_OUT/app/entitlements.plist" "$APP"
  echo "$stamp" >"$SUITE_OUT/app/stamp"
}

# setup_plugins: the -pluginsDirectory, with a catalog whose future lastUpdate keeps PluginSync from downloading
setup_plugins() {
  local build
  build=$(plutil -extract CFBundleVersion raw "$APP/Contents/Info.plist") || return 1
  rm -rf "$PLUGINS"
  mkdir -p "$PLUGINS"
  cp "$DYLIB" "$PLUGINS/"
  printf '{"Version":3,"CoronaBuild":"%s","com.studycat.spine/plugin.spine":{"lastUpdate":2100000000}}\n' \
    "$build" >"$PLUGINS/catalog.json"
}

# setup_project: tests/sim as a Solar2D project with the sample skeletons the scenarios load
setup_project() {
  local s
  rm -rf "$PROJECT"
  mkdir -p "$PROJECT/spines" "$SUITE_OUT/results" "$SIM_HOME"
  cp "$W"/*.lua "$W/build.settings" "$PROJECT/"
  for s in raptor snowglobe spineboy; do cp -R "$SPINE_SPINES/$s" "$PROJECT/spines/"; done
}

result_file() { printf '%s/results/%s.txt' "$SUITE_OUT" "$(printf '%s' "$1" | tr '/ ' '__')"; }

# scenario test script arg: one Simulator run of script; prints the Simulator output, then the results file
scenario() {
  local test=$1 script=$2 arg=$3 out pid rc=0 i=0
  out=$(result_file "$test")
  rm -f "$out"
  printf '%s\n%s\n%s\n' "${script%.lua}" "$arg" "$out" >"$PROJECT/scenario.txt"
  HOME=$SIM_HOME CFFIXED_USER_HOME=$SIM_HOME "$APP/Contents/MacOS/Corona Simulator" -no-console YES \
    -allowLuaExit YES -NSAppSleepDisabled YES -ApplePersistenceIgnoreState YES \
    -suppressUnsupportedOSWarning "$(sw_vers -productVersion)" -pluginsDirectory "$PLUGINS" \
    -project "$PROJECT/main.lua" </dev/null &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && (( i < TIMEOUT_S * 5 )); do sleep 0.2; i=$((i + 1)); done
  if kill -0 "$pid" 2>/dev/null; then echo "sim: timeout after ${TIMEOUT_S}s, killing $pid"; kill -9 "$pid"; fi
  wait "$pid" || rc=$?
  echo "== exit $rc; results $out"
  cat "$out" 2>/dev/null || true
  (( rc == 0 )) && grep -q $'^DONE exit\t0$' "$out" && ! grep -qE $'^(UNHANDLED_ERROR|ERROR)\t' "$out"
}

build_dylib
make_app
setup_plugins
setup_project
while read -r script arg; do
  [[ -z "$script" || "$script" == \#* ]] && continue
  test="${script%.lua}${arg:+ $arg}"
  run_test "$test" scenario "$test" "$script" "$arg"
  out=$(result_file "$test")
  [[ -f "$out" ]] || continue
  awk -F'\t' '$1 == "CHECK" { print $2 "\t" $3 }' "$out" | while IFS=$'\t' read -r verdict check; do
    record "$verdict" "$test $check"
  done
done <"$W/scenarios"
