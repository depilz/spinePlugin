#!/bin/bash
# Release builder: builds and packs one Spine line's data.tgz archives from a clean clone of the commit being released.
# usage: <clone>/tools/release/build.sh <line> --commit REV --out DIR [--symbols DIR]
#                                       [--dll FILE --dll-sha256 HEX --dll-log FILE] [platform...]
# Platforms: android iphone iphone-sim mac-sim win32-sim linux-sim (the default set; iphone-sim needs iphone).
# The clone holding this script must be a plain git clone (.git a directory) with no modified, untracked or ignored
# file, whose HEAD^{tree} equals REV^{tree}. OUT (absent or empty) and the symbols dir lie outside the clone.
# Writes OUT/plugin.spine<NN>/<platform>/data.tgz, each packed by pack.sh with the epoch of the last commit outside
# plugin/ (iphone-sim a byte copy of iphone), OUT/pack.log (commit, tree, epoch, toolchains, sha256 of every binary
# and archive), OUT/logs/ and OUT/work/. android: android/build.sh; iphone: xcodebuild of the line's ios project;
# mac-sim: tests/sim/suite.sh's build_dylib, then strip -S and an ad-hoc re-sign, its dSYM to <symbols>/mac-sim/;
# win32-sim: the VM-built DLL --dll, checked against --dll-sha256, its build log --dll-log copied to OUT/logs/;
# linux-sim: the Lua stub linux/plugin_spine<NN>.lua. Fails when a spine entry of the user's Simulator plugins dir
# changes. Toolchains, overridable by env: DEVELOPER_DIR (Xcode 26.4), ANDROID_NDK (30.0.16248370), CORONA (3731).
# Exit 0 = every archive written, 1 = a build step failed, 2 = usage or precondition error.
set -euo pipefail

PLATFORMS="android iphone iphone-sim mac-sim win32-sim linux-sim"

usage() { sed -n '3,5s/^# //p' "$0"; }
die() { echo "build.sh: $*" >&2; exit 2; }
fail() { echo "build.sh: $*" >&2; exit 1; }
value() { [[ -n "${2:-}" ]] || die "$1 needs a value"; }
# outside dir: dir (existing) does not lie inside the clone
outside() { [[ "$(cd "$1" && pwd -P)/" != "$REPO_P/"* ]]; }
# place dir: creates dir outside the clone (its parent must exist, so nothing is created inside) and prints its
# physical path
place() {
  [[ -d "$(dirname "$1")" ]] && outside "$(dirname "$1")" || die "$1 must lie outside the clone, in an existing directory"
  mkdir -p "$1" && outside "$1" || die "$1 lies inside the clone"
  cd "$1" && pwd -P
}
note() { printf '%s\n' "$*" >>"$OUT/pack.log"; }
# sums path...: sha256 of each path (relative to OUT) into pack.log
sums() { (cd "$OUT" && shasum -a 256 "$@") >>"$OUT/pack.log"; }
# pack platform tree [member...]: OUT/plugin.spine<NN>/<platform>/data.tgz from tree
pack() {
  mkdir -p "$PKG/$1"
  "$REPO/tools/release/pack.sh" --mtime "$EPOCH" "$2" "$PKG/$1/data.tgz" "${@:3}"
}

REPO=$(cd "$(dirname "$0")/../.." && pwd)
REPO_P=$(cd "$REPO" && pwd -P)
[[ "${1:-}" == -h || "${1:-}" == --help ]] && { usage; exit 0; }
LINE=${1:-}
[[ -n "$LINE" && "$LINE" != -* ]] || { usage >&2; exit 2; }
shift
COMMIT="" OUT="" SYMBOLS="" DLL="" DLL_SHA="" DLL_LOG=""
while (( $# )); do
  case $1 in
    --commit) value "$@"; COMMIT=$2; shift 2 ;;
    --out) value "$@"; OUT=$2; shift 2 ;;
    --symbols) value "$@"; SYMBOLS=$2; shift 2 ;;
    --dll) value "$@"; DLL=$2; shift 2 ;;
    --dll-sha256) value "$@"; DLL_SHA=$2; shift 2 ;;
    --dll-log) value "$@"; DLL_LOG=$2; shift 2 ;;
    -*) die "unknown option $1 (--help)" ;;
    *) break ;;
  esac
done
for plat in "$@"; do [[ " $PLATFORMS " == *" $plat "* ]] || die "unknown platform '$plat' (one of: $PLATFORMS)"; done
(( $# )) || set -- $PLATFORMS
WANT=" $* "
NN=${LINE//./}
[[ -d "$REPO/runtime/spine-$LINE/spine" ]] || die "unknown Spine line '$LINE' (no runtime/spine-$LINE)"
[[ -n "$COMMIT" && -n "$OUT" ]] || die "--commit and --out are required"
[[ "$WANT" != *" iphone-sim "* || "$WANT" == *" iphone "* ]] || die "iphone-sim is a copy of iphone: select iphone too"

# the clone: plain, clean, and at the released tree
[[ -d "$REPO/.git" ]] || die "$REPO is not a plain git clone"
[[ -z "$(git -C "$REPO" status --porcelain --ignored --untracked-files=all)" ]] || die "$REPO is not clean"
TREE=$(git -C "$REPO" rev-parse 'HEAD^{tree}')
[[ "$TREE" == "$(git -C "$REPO" rev-parse --verify -q "$COMMIT^{tree}")" ]] || die "HEAD^{tree} of $REPO is not $COMMIT^{tree}"
EPOCH=$(git -C "$REPO" log -1 --format=%ct HEAD -- . ':(exclude)plugin')

OUT=$(place "$OUT") || exit 2
[[ -z "$(ls -A "$OUT")" ]] || die "--out $OUT is not empty"
if [[ "$WANT" == *" mac-sim "* ]]; then
  [[ -n "$SYMBOLS" ]] || die "mac-sim needs --symbols"
  SYMBOLS=$(place "$SYMBOLS") || exit 2
  mkdir -p "$SYMBOLS/mac-sim"
fi
if [[ "$WANT" == *" win32-sim "* ]]; then
  [[ -f "$DLL" && -f "$DLL_LOG" && -n "$DLL_SHA" ]] || die "win32-sim needs --dll, --dll-sha256 and --dll-log"
  [[ "$(shasum -a 256 "$DLL" | cut -d' ' -f1)" == "$(tr A-F a-f <<<"$DLL_SHA")" ]] || die "sha256 of $DLL is not $DLL_SHA"
fi
if [[ "$WANT" == *" linux-sim "* ]]; then
  [[ -f "$REPO/linux/plugin_spine$NN.lua" ]] || die "no linux/plugin_spine$NN.lua for line $LINE"
fi

export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode_26.4.app/Contents/Developer}
export SDKROOT=${SDKROOT:-$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.4.sdk}
ANDROID_NDK=${ANDROID_NDK:-$HOME/Library/Android/sdk/ndk/30.0.16248370}
CORONA=${CORONA:-/Applications/Corona-3731}
PKG=$OUT/plugin.spine$NN WORK=$OUT/work LOGS=$OUT/logs
IOS_PROJECT=ios/Plugin.xcodeproj MAC_PROJECT=mac/Plugin.xcodeproj
[[ "$LINE" == 4.2 ]] || IOS_PROJECT=ios/Plugin$NN.xcodeproj MAC_PROJECT=mac/Plugin$NN.xcodeproj
mkdir -p "$WORK" "$LOGS"
note "line $LINE commit $(git -C "$REPO" rev-parse HEAD) tree $TREE"
note "epoch $EPOCH"
note "toolchains xcode $DEVELOPER_DIR ndk $ANDROID_NDK corona $CORONA"

build_android() {
  local b=$WORK/android
  (cd "$REPO" && ANDROID_NDK=$ANDROID_NDK CORONA=$CORONA BUILD_DIR=$b android/build.sh "$LINE") >"$LOGS/android.log" 2>&1
  pack android "$b" metadata.lua jniLibs
  (cd "$OUT" && find "work/android/jniLibs" -type f | sort | xargs shasum -a 256) >>"$OUT/pack.log"
}

build_iphone() {
  local t=$WORK/iphone
  (cd "$REPO" && env -u SDKROOT ZERO_AR_DATE=1 "$DEVELOPER_DIR/usr/bin/xcodebuild" -project "$IOS_PROJECT" \
    -scheme plugin_library -configuration Release -sdk iphoneos -derivedDataPath "$WORK/dd-ios" \
    CORONA_ROOT="$CORONA/Native" build) >"$LOGS/iphone.log" 2>&1
  mkdir -p "$t"
  cp "$WORK/dd-ios/Build/Products/Release-iphoneos/libplugin_spine$NN.a" "$t/"
  cp "$REPO/ios/metadata-$LINE.lua" "$t/metadata.lua"
  pack iphone "$t"
  sums "work/iphone/libplugin_spine$NN.a"
}

copy_iphone_sim() {
  mkdir -p "$PKG/iphone-sim"
  cp "$PKG/iphone/data.tgz" "$PKG/iphone-sim/data.tgz"
}

build_mac_sim() {
  local product=plugin_spine$NN dir
  build_dylib "$MAC_PROJECT" "$product" HEAD >"$LOGS/mac-sim.log" 2>&1
  dir=$(dirname "${DYLIBS[${#DYLIBS[@]} - 1]}")
  cat "$dir/build.log" >>"$LOGS/mac-sim.log"
  # stripping the stabs debug map invalidates the signature, so strip the unsigned product, then sign it
  mkdir -p "$WORK/mac-sim-unsigned" "$WORK/mac-sim"
  strip -S "$dir/dd/Build/Products/Release/$product.dylib" -o "$WORK/mac-sim-unsigned/$product.dylib"
  codesign --remove-signature "$WORK/mac-sim-unsigned/$product.dylib"
  cp "$WORK/mac-sim-unsigned/$product.dylib" "$WORK/mac-sim/"
  codesign -f -s - "$WORK/mac-sim/$product.dylib"
  codesign -v "$WORK/mac-sim/$product.dylib"
  rm -rf "$SYMBOLS/mac-sim/$product.dylib.dSYM"
  cp -R "$dir/dd/Build/Products/Release/$product.dylib.dSYM" "$SYMBOLS/mac-sim/"
  pack mac-sim "$WORK/mac-sim"
  sums "work/mac-sim-unsigned/$product.dylib" "work/mac-sim/$product.dylib"
}

pack_win32_sim() {
  mkdir -p "$WORK/win32-sim"
  cp "$DLL" "$WORK/win32-sim/plugin_spine$NN.dll"
  cp "$DLL_LOG" "$LOGS/win32-msbuild.log"
  pack win32-sim "$WORK/win32-sim"
  sums "work/win32-sim/plugin_spine$NN.dll"
}

pack_linux_sim() {
  mkdir -p "$WORK/linux-sim"
  cp "$REPO/linux/plugin_spine$NN.lua" "$WORK/linux-sim/"
  pack linux-sim "$WORK/linux-sim"
}

if [[ "$WANT" == *" mac-sim "* ]]; then
  # build_dylib and the user-Plugins snapshot come from the sim suite; its copy phase lands under WORK, HOME is fake
  export SOLAR2D_SIM_APP=${SOLAR2D_SIM_APP:-$CORONA/Corona Simulator.app} SPINE_REPO=$REPO SPINE_RUNTIME=$LINE
  export SPINE_TEST_OUT=$WORK/test-out SUITE_OUT=$WORK/sim SPINE_SUITE=release-build SUITE_RESULTS=$WORK/guard.tsv
  source "$REPO/tests/sim/suite.sh"
fi

# a failing command anywhere in a platform's build ends the run with exit 1
set -E
trap 'fail "$plat failed (logs in $LOGS)"' ERR
for plat in $PLATFORMS; do
  [[ "$WANT" == *" $plat "* ]] || continue
  echo "build.sh: $plat"
  case $plat in
    android) build_android ;;
    iphone) build_iphone ;;
    iphone-sim) copy_iphone_sim ;;
    mac-sim) build_mac_sim ;;
    win32-sim) pack_win32_sim ;;
    linux-sim) pack_linux_sim ;;
  esac
done
trap - ERR

if [[ "$WANT" == *" mac-sim "* ]]; then
  trap - EXIT
  guard_user_plugins
  ! grep -q $'\tFAIL\t' "$SUITE_RESULTS" || fail "a spine entry of the user's Simulator plugins dir changed"
fi
(cd "$OUT" && find "plugin.spine$NN" -name data.tgz | sort | xargs shasum -a 256) >>"$OUT/pack.log"
echo "build.sh: $PKG"
