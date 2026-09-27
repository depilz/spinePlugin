#!/bin/bash
# Release gate over the internal package layout: <plugin-dir>/<platform>/data.tgz.
# usage: tools/release-gate/gate.sh [--repo DIR] [--line 4.2|4.3] [--plugin-dir DIR] [--version vX.Y.Z] [--runtime X.Y]
#                                   [--entry NAME] [platform...]
# Platforms: android iphone mac-sim win32 (default: all four). Defaults come from the line's runtime (default 4.2) in
# the repo (the checkout holding this script): runtime/spine-<line>/spine/Version.h gives the version
# (SPINE_PLUGIN_VERSION), the runtime (SPINE_VERSION_STRING) and the entry plugin_spine<major><minor>; the archives
# default to plugin/com.studycat.spine/plugin.spine.
# Every binary must carry exactly the version literal, the runtime literal and no other Spine runtime's, 4.3-only
# symbols on runtime 4.3 and none on an older runtime, the entry symbol, and its platform's architecture (android: the
# 4 ABIs, 16 KB LOAD alignment on 64-bit; iphone: arm64 device slice; mac-sim: universal and codesigned; win32: PE32).
# Prints OK|FAIL per binary and per archive; exit 0 = every archive passed, 1 = a check failed, 2 = usage error.
set -uo pipefail

PLATFORMS="android iphone mac-sim win32"
ANDROID_ABIS="arm64-v8a armeabi-v7a x86 x86_64"
SPINE_RUNTIMES="3.8 4.0 4.1 4.2 4.3"   # other X.Y strings in a binary are toolchain noise (F32), never a runtime

usage() { sed -n '3,4s/^# //p' "$0"; }
die() { echo "gate.sh: $*" >&2; exit 2; }
value() { [[ -n "${2:-}" ]] || die "$1 needs a value"; }

# tree_value file sed-expression what: the value the expression prints from a file in the repo
tree_value() {
  local v
  v=$(sed -n "$2" "$REPO/$1" 2>/dev/null)
  [[ -n "$v" ]] || die "no $3 in $REPO/$1; pass it by flag"
  echo "$v"
}

# elf_info file: "<e_machine> <smallest PT_LOAD alignment>" of an ELF shared object
elf_info() {
  python3 - "$1" <<'PY'
import struct, sys
b = open(sys.argv[1], 'rb').read()
wide = b[4] == 2
phoff, = struct.unpack_from('<Q' if wide else '<I', b, 32 if wide else 28)
phes, phn = struct.unpack_from('<HH', b, 54 if wide else 42)
fmt = '<IIQQQQQQ' if wide else '<IIIIIIII'
aligns = [e[7] for e in (struct.unpack_from(fmt, b, phoff + i * phes) for i in range(phn)) if e[0] == 1]
print(struct.unpack_from('<H', b, 18)[0], min(aligns))
PY
}

# android_machine abi: the ELF e_machine an ABI's library must have
android_machine() {
  case $1 in armeabi-v7a) echo 40 ;; arm64-v8a) echo 183 ;; x86) echo 3 ;; x86_64) echo 62 ;; *) echo none ;; esac
}

markers_forbidden() { case $RUNTIME in [0-3].*|4.[0-2]) true ;; *) false ;; esac; }

# platform_checks platform file: the architecture and signature checks; appends to info and why
platform_checks() {
  local abi machine align archs ids
  case $1 in
    android)
      abi=$(basename "$(dirname "$2")")
      read -r machine align < <(elf_info "$2")
      info="machine=$machine align=$align"
      [[ "$machine" == "$(android_machine "$abi")" ]] || why+=" arch"
      case $abi in arm64-v8a|x86_64) (( align >= 16384 )) || why+=" 16k-align" ;; esac ;;
    iphone)
      archs=$(lipo -archs "$2" 2>/dev/null)
      ids=$(otool -l "$2" 2>/dev/null | awk '/LC_BUILD_VERSION/{b=1} b&&/platform/{print $2; b=0} /LC_VERSION_MIN_IPHONEOS/{print "2"}' | sort -u | tr '\n' ' ')
      info="archs=[$archs] platform-ids=[$ids]"   # 2 = iOS device
      [[ " $archs " == *" arm64 "* ]] || why+=" archs"
      [[ " $ids" == *" 2 "* ]] || why+=" not-a-device-slice" ;;
    mac-sim)
      archs=$(lipo -archs "$2" 2>/dev/null)
      info="archs=[$archs] signature=$(codesign -dv "$2" 2>&1 | sed -n 's/^Signature=//p')"
      [[ " $archs " == *" arm64 "* && " $archs " == *" x86_64 "* ]] || why+=" archs"
      codesign -v "$2" 2>/dev/null || why+=" unsigned" ;;
    win32)
      info="file=[$(file -b "$2")]"
      file -b "$2" | grep -q '^PE32 executable' || why+=" not-PE32" ;;
  esac
}

# check_binary platform file: one OK|FAIL line; clears archive_ok on failure
check_binary() {
  local v rt markers entry info="" why=""
  v=$(strings -a "$2" | grep -xE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -u | tr '\n' ' ')
  rt=$(strings -a -n 3 "$2" | grep -xF -e "$RUNTIME" $(printf -- '-e %s ' $SPINE_RUNTIMES) | sort -u | tr '\n' ' ')
  markers=$(strings -a "$2" | grep -cE 'SlotPose|SliderData|SliderTimeline')
  case $2 in
    *.so|*.dll) entry=$(strings -a "$2" | grep -cxF "luaopen_$ENTRY") ;;
    *) entry=$(nm -gU "$2" 2>/dev/null | grep -cE " _?luaopen_$ENTRY\$") ;;
  esac
  [[ "$v" == "$VERSION " ]] || why+=" version"
  [[ "$rt" == "$RUNTIME " ]] || why+=" runtime"
  if markers_forbidden; then (( markers == 0 )) || why+=" 4.3-markers"
  else (( markers )) || why+=" no-4.3-markers"; fi
  (( entry )) || why+=" entry"
  platform_checks "$1" "$2"
  report "$1/${2#"$TMP/$1/"} version=[$v] runtime=[$rt] 4.3-markers=$markers entry=$entry $info"
}

# report line: OK or FAIL (with why) for the line
report() {
  if [[ -z "$why" ]]; then echo "OK   $1"; else echo "FAIL $1 ::$why"; archive_ok=0; fi
}

# check_metadata platform binaries...: metadata.lua staticLibs names a shipped library
check_metadata() {
  local plat=$1 meta="$TMP/$1/metadata.lua" libs have l why=" staticLibs"
  shift
  [[ -f "$meta" ]] || return 0
  libs=$(sed -n 's/.*staticLibs *= *{ *\(.*\) *}.*/\1/p' "$meta" | tr -d "\"' ,")
  have=$(for l in "$@"; do l=$(basename "$l"); l=${l%.*}; echo "${l#lib}"; done | sort -u | tr '\n' ' ')
  for l in $libs; do [[ " $have" == *" ${l#lib} "* ]] && why=""; done
  report "$plat/metadata.lua staticLibs=[$libs] binaries=[$have]"
}

# check_archive platform: every check on <plugin-dir>/<platform>/data.tgz, then its OK|FAIL line; clears ok on failure
check_archive() {
  local plat=$1 archive="$PLUGIN_DIR/$1/data.tgz" f bins=() abis why=""
  archive_ok=1
  mkdir -p "$TMP/$plat"
  if [[ ! -f "$archive" ]]; then why=" missing"
  elif ! tar xzf "$archive" -C "$TMP/$plat"; then why=" unreadable"
  else
    while IFS= read -r f; do bins+=("$f"); done < <(find "$TMP/$plat" -type f \( -name '*.so' -o -name '*.a' -o -name '*.dylib' -o -name '*.dll' \) | sort)
    (( ${#bins[@]} )) || why=" no-binary"
    for f in ${bins[@]+"${bins[@]}"}; do check_binary "$plat" "$f"; done
    check_metadata "$plat" ${bins[@]+"${bins[@]}"}
    if [[ $plat == android ]]; then
      abis=$(ls "$TMP/android/jniLibs" 2>/dev/null | sort | tr '\n' ' ')
      [[ "$abis" == "$ANDROID_ABIS " ]] || why=" abis=[$abis]"
    fi
  fi
  [[ -z "$why" ]] || archive_ok=0
  if (( archive_ok )); then echo "OK   $plat/data.tgz"; else echo "FAIL $plat/data.tgz${why:+ ::$why}"; ok=0; fi
}

REPO=$(cd "$(dirname "$0")/../.." && pwd)
LINE=4.2 PLUGIN_DIR="" VERSION="" RUNTIME="" ENTRY=""
while (( $# )); do
  case $1 in
    -h|--help) usage; exit 0 ;;
    --repo) value "$@"; REPO=$2; shift 2 ;;
    --line) value "$@"; LINE=$2; shift 2 ;;
    --plugin-dir) value "$@"; PLUGIN_DIR=$2; shift 2 ;;
    --version) value "$@"; VERSION=$2; shift 2 ;;
    --runtime) value "$@"; RUNTIME=$2; shift 2 ;;
    --entry) value "$@"; ENTRY=$2; shift 2 ;;
    -*) die "unknown option $1 (--help)" ;;
    *) break ;;
  esac
done
for plat in "$@"; do [[ " $PLATFORMS " == *" $plat "* ]] || die "unknown platform '$plat' (one of: $PLATFORMS)"; done
(( $# )) || set -- $PLATFORMS
PLUGIN_DIR=${PLUGIN_DIR:-$REPO/plugin/com.studycat.spine/plugin.spine}
VERSION_H=runtime/spine-$LINE/spine/Version.h
[[ -n "$VERSION" ]] || VERSION=$(tree_value "$VERSION_H" 's/^#define SPINE_PLUGIN_VERSION "\(.*\)"$/\1/p' SPINE_PLUGIN_VERSION) || exit 2
[[ -n "$RUNTIME" ]] || RUNTIME=$(tree_value "$VERSION_H" 's/^#define SPINE_VERSION_STRING "\(.*\)"$/\1/p' SPINE_VERSION_STRING) || exit 2
[[ -n "$ENTRY" ]] || ENTRY=plugin_spine$(tree_value "$VERSION_H" 's/^#define SPINE_M[AI][JN]OR_VERSION \([0-9]*\)$/\1/p' SPINE_MAJOR/MINOR_VERSION | tr -d '\n') || exit 2

TMP=$(mktemp -d "${TMPDIR:-/tmp}/release-gate.XXXXXX") || exit 2
trap 'rm -rf "$TMP"' EXIT
echo "expect $VERSION runtime $RUNTIME entry luaopen_$ENTRY in $PLUGIN_DIR"
ok=1
for plat in "$@"; do check_archive "$plat"; done
(( ok )) || exit 1
