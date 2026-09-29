#!/bin/bash
# run.sh: named-only
# sim: every scenario in ./scenarios in an isolated copy of the Solar2D Simulator ($SOLAR2D_SIM_APP), one Simulator
# process per scenario, on the line's plugin (plugin.spine42 on 4.2, plugin.spine43 on 4.3). plugin_spine42.dylib and
# plugin_spine43.dylib are built by xcodebuild from a git archive of HEAD (so uncommitted changes are not in them) and
# share one plugins dir; on 4.2 the shipped 1.5.0 plugin_spine.dylib from the tracked mac-sim archive (the baseline of
# s17_digest) sits next to them. build.settings is generated per run and names the line's plugin, which simlib loads;
# the project also gets the tint-black fixture of both lines (assets/tintblack/<line>/ as tintblack/<line>/).
# A scenario passes when it runs to "DONE exit 0" with no unhandled or logged error; its CHECK lines are recorded as
# "<test> <check>" (a check declared by an EXPECT line that never reported, as when it crashed first, as FAIL; a
# scenario script with a <script>.py next to it gets that checker's CHECK lines, over its results and stdout, too), and
# every scenario records "<test> identity" (its stdout carries exactly the load banner of the plugin it should load,
# from the line's Version.h; s21_tint_black both loads both lines' plugins and carries both banners, the line's first)
# and "<test> cpath" (the first package.cpath entry is the isolated
# plugins dir: isolation, not identity, since both dylibs sit there). Nothing is written to the user's Simulator
# Plugins dir or its preferences domain (the copy's own ...spinetests preferences and crash reports do land under
# ~/Library), and the suite fails if any plugin_spine* or plugin.spine* entry of the user's Plugins dir
# ($SPINE_SIM_USER_PLUGINS, default ~/Library/Application Support/Corona/Simulator/Plugins) changes while it runs, a
# write inside plugin.spine/ included.
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
PLUGIN=plugin.spine${SPINE_RUNTIME//./}
BASE_TEST="s17_digest base" # loads the 1.5.0 plugin.spine, not the line's plugin
BASE_BANNER="Solar2d Spine plugin v1.5.0 loaded with Spine 4.2.XX"
BOTH_TEST="s21_tint_black both" # loads the line's plugin, then the other line's
OTHER_RUNTIME=$([[ "$SPINE_RUNTIME" == 4.2 ]] && echo 4.3 || echo 4.2)

USER_HOME=$(dscl . -read "/Users/$(id -un)" NFSHomeDirectory | sed 's/^NFSHomeDirectory: //')
USER_PLUGINS=${SPINE_SIM_USER_PLUGINS:-"$USER_HOME/Library/Application Support/Corona/Simulator/Plugins"}
# user_plugins_snapshot: "name mtime size newest-mtime-beneath" per spine entry of $USER_PLUGINS; stat/find only
user_plugins_snapshot() {
  local e
  for e in "$USER_PLUGINS"/plugin_spine* "$USER_PLUGINS"/plugin.spine*; do
    [[ -e "$e" || -L "$e" ]] || continue
    printf '%s %s %s\n' "${e##*/}" "$(stat -f '%m %z' "$e")" "$(find "$e" -exec stat -f %m {} + | sort -n | tail -1)"
  done | sort
}
USER_PLUGINS_BEFORE=$(user_plugins_snapshot)
guard_user_plugins() {
  local after
  after=$(user_plugins_snapshot)
  if [[ "$after" == "$USER_PLUGINS_BEFORE" ]]; then record PASS "user Plugins spine entries unchanged"; return; fi
  printf 'user Plugins spine entries in %s\nbefore:\n%s\nafter:\n%s\n' "$USER_PLUGINS" "$USER_PLUGINS_BEFORE" "$after"
  record FAIL "user Plugins spine entries unchanged"
}
trap guard_user_plugins EXIT

# build_dylib project product: $DYLIB_CACHE/<product>/<HEAD>/<product>.dylib, ad-hoc signed, appended to DYLIBS.
# DYLIB_CACHE sits next to the line's SPINE_TEST_OUT, so the lines of one tests/run.sh run share it and the second
# line reports a cache hit. The project's "Copy to Simulator's Plugin Directory" phase is pointed at
# <product>/<HEAD>/copied (and HOME at a fake home) before building.
DYLIB_CACHE=$(dirname "$SPINE_TEST_OUT")/sim-dylib
DYLIBS=()
build_dylib() {
  local project=$1 product=$2 head dir tree pbx
  head=$(git -C "$SPINE_REPO" rev-parse HEAD) || return 1
  dir=$DYLIB_CACHE/$product/$head
  DYLIBS+=("$dir/$product.dylib")
  if [[ -f "$dir/$product.dylib" ]]; then echo "sim: $product cache hit $dir"; return; fi
  echo "sim: $product building $dir"
  rm -rf "$DYLIB_CACHE/$product"
  tree=$dir/tree
  pbx=$tree/$project/project.pbxproj
  mkdir -p "$tree" "$dir/copied" "$dir/home"
  git -C "$SPINE_REPO" archive HEAD | tar -x -C "$tree" || return 1
  sed -i '' 's#PLUGINS_DIR=\\"${HOME}/Library/Application Support/Corona/Simulator/Plugins\\"#PLUGINS_DIR=\\"'"$dir/copied"'\\"#' "$pbx"
  if grep -q 'Corona/Simulator/Plugins' "$pbx" || ! grep -qF "PLUGINS_DIR=\\\"$dir/copied\\\"" "$pbx"; then
    echo "sim: could not redirect the Copy to Simulator's Plugin Directory phase in $pbx" >&2
    return 1
  fi
  DEVELOPER_DIR=$DEVELOPER_DIR "$DEVELOPER_DIR/usr/bin/xcodebuild" -project "$tree/$project" \
    -scheme "$product" -configuration Release -derivedDataPath "$dir/dd" -destination 'generic/platform=macOS' \
    ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO HOME="$dir/home" CORONA_ROOT="$CORONA_ROOT" build \
    >"$dir/build.log" 2>&1 || { tail -30 "$dir/build.log" >&2; return 1; }
  # the copy phase runs before signing: take the DerivedData product and sign it
  cp "$dir/dd/Build/Products/Release/$product.dylib" "$dir/$product.unsigned"
  codesign -f -s - "$dir/$product.unsigned" && mv "$dir/$product.unsigned" "$dir/$product.dylib"
}

# line_banner [runtime]: the load banner of the line's (or runtime's) plugin, from its Version.h at HEAD
line_banner() {
  local h
  h=$(git -C "$SPINE_REPO" show "HEAD:runtime/spine-${1:-$SPINE_RUNTIME}/spine/Version.h") || return 1
  printf 'Solar2d Spine plugin %s loaded with Spine %s\n' \
    "$(sed -n 's/^#define SPINE_PLUGIN_VERSION "\(.*\)"$/\1/p' <<<"$h")" \
    "$(sed -n 's/^#define SPINE_VERSION_STRING "\(.*\)"$/\1/p' <<<"$h")"
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

# setup_plugins: the -pluginsDirectory, with a catalog whose future lastUpdate keeps PluginSync from downloading.
# The 1.5.0 dylib, staged on 4.2 only, ships unsigned and is ad-hoc signed here.
setup_plugins() {
  local build entries='"com.studycat.spine/plugin.spine42":{"lastUpdate":2100000000},"com.studycat.spine/plugin.spine43":{"lastUpdate":2100000000}'
  build=$(plutil -extract CFBundleVersion raw "$APP/Contents/Info.plist") || return 1
  rm -rf "$PLUGINS"
  mkdir -p "$PLUGINS"
  cp "${DYLIBS[@]}" "$PLUGINS/"
  if [[ "$SPINE_RUNTIME" == 4.2 ]]; then
    git -C "$SPINE_REPO" show HEAD:plugin/com.studycat.spine/plugin.spine/mac-sim/data.tgz |
      tar -xzf - -C "$PLUGINS" plugin_spine.dylib || return 1
    codesign -f -s - "$PLUGINS/plugin_spine.dylib" || return 1
    entries+=',"com.studycat.spine/plugin.spine":{"lastUpdate":2100000000}'
  fi
  printf '{"Version":3,"CoronaBuild":"%s",%s}\n' "$build" "$entries" >"$PLUGINS/catalog.json"
}

# setup_project: tests/sim as a Solar2D project with the line's exports and a build.settings naming the line's plugin
# (and plugin.spine on 4.2)
setup_project() {
  local s p plugins=("$PLUGIN")
  [[ "$SPINE_RUNTIME" == 4.2 ]] && plugins+=(plugin.spine)
  rm -rf "$PROJECT"
  mkdir -p "$PROJECT/spines" "$SUITE_OUT/results" "$SIM_HOME"
  cp "$W"/*.lua "$PROJECT/"
  for s in "$SPINE_SPINES"/*/; do cp -R "${s%/}" "$PROJECT/spines/"; done
  mkdir -p "$PROJECT/tintblack"
  for s in "$W"/assets/tintblack/*/; do cp -R "${s%/}" "$PROJECT/tintblack/"; done
  {
    printf 'settings =\n{\n    plugins =\n    {\n'
    for p in "${plugins[@]}"; do printf "        ['%s'] = {publisherId = 'com.studycat.spine'},\n" "$p"; done
    printf '    },\n}\n'
  } >"$PROJECT/build.settings"
}

result_file() { printf '%s/results/%s.txt' "$SUITE_OUT" "$(printf '%s' "$1" | tr '/ ' '__')"; }
stdout_file() { printf '%s/results/%s.stdout.log' "$SUITE_OUT" "$(printf '%s' "$1" | tr '/ ' '__')"; }

# scenario test script arg: one Simulator run of script, its stdout in stdout_file; prints that, then the results file
scenario() {
  local test=$1 script=$2 arg=$3 out pid rc=0 i=0
  out=$(result_file "$test")
  rm -f "$out"
  printf '%s\n%s\n%s\n' "${script%.lua}" "$arg" "$out" >"$PROJECT/scenario.txt"
  HOME=$SIM_HOME CFFIXED_USER_HOME=$SIM_HOME "$APP/Contents/MacOS/Corona Simulator" -no-console YES \
    -allowLuaExit YES -NSAppSleepDisabled YES -ApplePersistenceIgnoreState YES \
    -suppressUnsupportedOSWarning "$(sw_vers -productVersion)" -pluginsDirectory "$PLUGINS" \
    -project "$PROJECT/main.lua" </dev/null >"$(stdout_file "$test")" 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && (( i < TIMEOUT_S * 5 )); do sleep 0.2; i=$((i + 1)); done
  if kill -0 "$pid" 2>/dev/null; then echo "sim: timeout after ${TIMEOUT_S}s, killing $pid"; kill -9 "$pid"; fi
  wait "$pid" || rc=$?
  cat "$(stdout_file "$test")"
  echo "== exit $rc; results $out"
  cat "$out" 2>/dev/null || true
  (( rc == 0 )) && grep -q $'^DONE exit\t0$' "$out" && ! grep -qE $'^(UNHANDLED_ERROR|ERROR)\t' "$out"
}

# verify test check want got: records "<test> <check>", PASS iff got is exactly want
verify() {
  if [[ "$4" == "$3" ]]; then record PASS "$1 $2"; return; fi
  printf 'sim: %s %s: want\n%s\ngot\n%s\n' "$1" "$2" "$3" "$4"
  record FAIL "$1 $2"
}

# identity test: the scenario's stdout carries exactly one load banner, the one of the plugin it should load
identity() {
  local want=$LINE_BANNER
  [[ "$1" == "$BASE_TEST" ]] && want=$BASE_BANNER
  [[ "$1" == "$BOTH_TEST" ]] && want=$LINE_BANNER$'\n'$OTHER_BANNER
  verify "$1" identity "$want" "$(grep '^Solar2d Spine plugin ' "$(stdout_file "$1")" 2>/dev/null)"
}

# cpath test: the first package.cpath entry simlib logged is the isolated plugins dir
cpath() {
  verify "$1" cpath "$PLUGINS/?.dylib" \
    "$(awk -F'\t' '$1 == "package.cpath" { split($2, e, ";"); print e[1]; exit }' "$(result_file "$1")" 2>/dev/null)"
}

LINE_BANNER=$(line_banner)
OTHER_BANNER=$(line_banner "$OTHER_RUNTIME")
build_dylib mac/Plugin.xcodeproj plugin_spine42
build_dylib mac/Plugin43.xcodeproj plugin_spine43
make_app
setup_plugins
setup_project
# a scenario line "<runtime>: script arg" runs on that line only
while read -r script arg; do
  [[ -z "$script" || "$script" == \#* ]] && continue
  if [[ "$script" == *: ]]; then
    [[ "${script%:}" == "$SPINE_RUNTIME" ]] || continue
    read -r script arg <<<"$arg"
  fi
  test="${script%.lua}${arg:+ $arg}"
  run_test "$test" scenario "$test" "$script" "$arg"
  identity "$test"
  cpath "$test"
  out=$(result_file "$test")
  [[ -f "$out" ]] || continue
  if [[ -f "$W/${script%.lua}.py" ]]; then
    python3 "$W/${script%.lua}.py" "$out" "$(stdout_file "$test")" >>"$out" || echo "sim: ${script%.lua}.py exited $?"
  fi
  awk -F'\t' '$1 == "CHECK" { print $2 "\t" $3; seen[$3] = 1 } $1 == "EXPECT" { want[++n] = $2 }
    END { for (i = 1; i <= n; i++) if (!(want[i] in seen)) print "FAIL\t" want[i] }' "$out" |
  while IFS=$'\t' read -r verdict check; do
    record "$verdict" "$test $check"
  done
done <"$W/scenarios"
