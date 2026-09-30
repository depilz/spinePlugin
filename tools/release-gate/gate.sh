#!/bin/bash
# Release gate over the internal package layout: <plugin-dir>/<platform>/data.tgz.
# usage: tools/release-gate/gate.sh [--repo DIR] [--line 4.2|4.3] [--plugin-dir DIR] [--version vX.Y.Z] [--runtime X.Y]
#                                   [--entry NAME] [--allow-legacy-metadata] [platform...]
# Platforms: android iphone iphone-sim mac-sim win32-sim linux-sim (the default set) and the legacy win32;
# iphone-sim's library must be byte-equal to the one in <plugin-dir>/iphone/data.tgz, so it needs that archive too.
# Defaults come from the line's runtime (default 4.2) in the repo (the checkout holding this script):
# runtime/spine-<line>/spine/Version.h gives the version (SPINE_PLUGIN_VERSION), the runtime (SPINE_VERSION_STRING)
# and the entry plugin_spine<major><minor>; the archives default to plugin/com.studycat/plugin.spine<major><minor>.
# Every binary must carry exactly the version literal, the runtime literal and no other Spine runtime's, 4.3-only
# symbols on runtime 4.3 and none on an older runtime, the entry symbol, and its platform's architecture (android: the
# 4 ABIs, 16 KB LOAD alignment on 64-bit; iphone, iphone-sim: arm64 device slice; mac-sim: universal and codesigned;
# win32, win32-sim: PE32). The literals of a Mach-O binary (.a, .dylib) are read from a `strip -S` copy, so debug info
# cannot supply one. linux-sim ships no binary: its Lua stub <entry>.lua must carry exactly the version literal.
# local-path: no build-machine path (/Users/, /private/, /tmp/, /var/folders, /Volumes/, a Windows drive or UNC path)
# in the raw bytes of any original binary, metadata.lua or stub, nor in the archive (raw and gunzipped), except where a
# LOCAL_PATH_ALLOW prefix starts at the hit. tar-meta: every archive member has uid/gid 0, empty uname/gname, no pax
# record and no ._* name. --allow-legacy-metadata waives both, for archives released before them.
# Prints OK|FAIL per binary and per archive; exit 0 = every archive passed, 1 = a check failed, 2 = usage error.
set -uo pipefail

DEFAULT_PLATFORMS="android iphone iphone-sim mac-sim win32-sim linux-sim"
PLATFORMS="$DEFAULT_PLATFORMS win32"
ANDROID_ABIS="arm64-v8a armeabi-v7a x86 x86_64"
SPINE_RUNTIMES="3.8 4.0 4.1 4.2 4.3"   # other X.Y strings in a binary are toolchain noise (F32), never a runtime
# local-path allowlist: toolchain paths no build option maps; none may overlap a user or temporary path
LOCAL_PATH_ALLOW=(
  /Volumes/Android/buildbot/   # the NDK's LLD records its own build tree in every .so's .comment
)

usage() { sed -n '3,6s/^# //p' "$0"; }
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

# local_path file: "0", or the count and first hits of build-machine paths in the file's bytes (a .tgz also gunzipped)
local_path() {
  python3 - "$1" "${LOCAL_PATH_ALLOW[@]}" <<'PY'
import gzip, re, sys
path, *allow = sys.argv[1:]
allow = tuple(a.encode() for a in allow)
user = (b'/Users/', b'/private/', b'/tmp/', b'/var/folders', b'/Volumes/Projects')
if any(a.startswith(u) or u.startswith(a) for a in allow for u in user):
    sys.exit('LOCAL_PATH_ALLOW overlaps a user path')
# a drive letter must follow a non-name byte and precede a name character, so V:\:e:q: and f:\~V are no hit
pattern = re.compile(rb'/Users/|/private/|/tmp/|/var/folders|/Volumes/|(?<![A-Za-z0-9])[A-Za-z]:\\\w|\\\\[\w.$-]+\\')

def gzip_header(data):   # a .tgz's raw bytes are scanned up to its file name and comment: deflate output is noise
    flags, end = data[3], 10
    if flags & 4: end += 2 + int.from_bytes(data[10:12], 'little')
    for flag in (8, 16):
        if flags & flag: end = data.index(b'\0', end) + 1
    return data[:end]

data = open(path, 'rb').read()
blobs = [gzip_header(data), gzip.decompress(data)] if path.endswith('.tgz') else [data]
hits = [(blob, m.start()) for blob in blobs for m in pattern.finditer(blob) if not blob.startswith(allow, m.start())]
text = re.compile(rb'[\x20-\x7e]{1,60}')
print(len(hits), *(text.match(blob, i).group().decode() for blob, i in hits[:3]))
PY
}

# tar_meta archive: "0", or the count and first members with an owner, a pax record or a ._* name
tar_meta() {
  python3 - "$1" <<'PY'
import os, sys, tarfile
bad = []
with tarfile.open(sys.argv[1]) as tar:
    for m in tar:
        why = [k for k in ('uid', 'gid', 'uname', 'gname') if getattr(m, k)]
        why += ['xattr' if any('.xattr.' in k for k in m.pax_headers) else 'pax'] if m.pax_headers else []
        why += ['appledouble'] if os.path.basename(m.name.rstrip('/')).startswith('._') else []
        if why: bad.append(f"{m.name}:{','.join(why)}")
    if tar.pax_headers: bad.append('global-pax')
print(len(bad), *bad[:3])
PY
}

# scan check file: unless --allow-legacy-metadata, runs the check (local_path, tar_meta) on the file; when it finds
# something or cannot run, appends its reason to the caller's why and its findings to the caller's found
scan() {
  local out
  (( ALLOW_LEGACY )) && return 0
  out=$("$1" "$2" 2>&1) || out="scan failed: ${out##*$'\n'}"
  [[ "$out" == 0 ]] && return 0
  why+=" ${1/_/-}"
  found+=" ${1/_/-}=[$out]"
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
    iphone|iphone-sim)
      archs=$(lipo -archs "$2" 2>/dev/null)
      ids=$(otool -l "$2" 2>/dev/null | awk '/LC_BUILD_VERSION/{b=1} b&&/platform/{print $2; b=0} /LC_VERSION_MIN_IPHONEOS/{print "2"}' | sort -u | tr '\n' ' ')
      info="archs=[$archs] platform-ids=[$ids]"   # 2 = iOS device
      [[ " $archs " == *" arm64 "* ]] || why+=" archs"
      [[ " $ids" == *" 2 "* ]] || why+=" not-a-device-slice"
      [[ $1 == iphone ]] || cmp -s "$2" "$TMP/iphone.ref/${2#"$TMP/$1/"}" || why+=" not-iphone-copy" ;;
    mac-sim)
      archs=$(lipo -archs "$2" 2>/dev/null)
      info="archs=[$archs] signature=$(codesign -dv "$2" 2>&1 | sed -n 's/^Signature=//p')"
      [[ " $archs " == *" arm64 "* && " $archs " == *" x86_64 "* ]] || why+=" archs"
      codesign -v "$2" 2>/dev/null || why+=" unsigned" ;;
    win32|win32-sim)
      info="file=[$(file -b "$2")]"
      file -b "$2" | grep -q '^PE32 executable' || why+=" not-PE32" ;;
  esac
}

# check_binary platform file: one OK|FAIL line; clears archive_ok on failure
check_binary() {
  local s=$2 v rt markers entry info="" why="" found=""
  case $2 in *.a|*.dylib) s=$TMP/stripped; cp "$2" "$s" && strip -S "$s" 2>/dev/null || s=$2 ;; esac
  v=$(strings -a "$s" | grep -xE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -u | tr '\n' ' ')
  rt=$(strings -a -n 3 "$s" | grep -xF -e "$RUNTIME" $(printf -- '-e %s ' $SPINE_RUNTIMES) | sort -u | tr '\n' ' ')
  markers=$(strings -a "$s" | grep -cE 'SlotPose|SliderData|SliderTimeline')
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
  scan local_path "$2"
  report "$1/${2#"$TMP/$1/"} version=[$v] runtime=[$rt] 4.3-markers=$markers entry=$entry $info$found"
}

# report line: OK or FAIL (with why) for the line
report() {
  if [[ -z "$why" ]]; then echo "OK   $1"; else echo "FAIL $1 ::$why"; archive_ok=0; fi
}

# check_stub: the linux-sim Lua stub <entry>.lua is present and carries exactly the version literal
check_stub() {
  local stub="$TMP/linux-sim/$ENTRY.lua" v why="" found=""
  [[ -f "$stub" ]] || why=" stub"
  v=$(grep -soE 'v[0-9]+\.[0-9]+\.[0-9]+' "$stub" | sort -u | tr '\n' ' ')
  [[ "$v" == "$VERSION " ]] || why+=" version"
  [[ ! -f "$stub" ]] || scan local_path "$stub"
  report "linux-sim/$ENTRY.lua version=[$v]$found"
}

# check_metadata platform binaries...: metadata.lua staticLibs names a shipped library
check_metadata() {
  local plat=$1 meta="$TMP/$1/metadata.lua" libs have l why=" staticLibs" found=""
  shift
  [[ -f "$meta" ]] || return 0
  libs=$(sed -n 's/.*staticLibs *= *{ *\(.*\) *}.*/\1/p' "$meta" | tr -d "\"' ,")
  have=$(for l in "$@"; do l=$(basename "$l"); l=${l%.*}; echo "${l#lib}"; done | sort -u | tr '\n' ' ')
  for l in $libs; do [[ " $have" == *" ${l#lib} "* ]] && why=""; done
  scan local_path "$meta"
  report "$plat/metadata.lua staticLibs=[$libs] binaries=[$have]$found"
}

# check_archive platform: every check on <plugin-dir>/<platform>/data.tgz, then its OK|FAIL line; clears ok on failure
check_archive() {
  local plat=$1 archive="$PLUGIN_DIR/$1/data.tgz" f bins=() abis why="" found=""
  archive_ok=1
  mkdir -p "$TMP/$plat"
  if [[ ! -f "$archive" ]]; then why=" missing"
  elif ! tar xzf "$archive" -C "$TMP/$plat"; then why=" unreadable"
  elif [[ $plat == linux-sim ]]; then check_stub
  else
    if [[ $plat == iphone-sim ]]; then
      mkdir -p "$TMP/iphone.ref"
      tar xzf "$PLUGIN_DIR/iphone/data.tgz" -C "$TMP/iphone.ref" 2>/dev/null
    fi
    while IFS= read -r f; do bins+=("$f"); done < <(find "$TMP/$plat" -type f \( -name '*.so' -o -name '*.a' -o -name '*.dylib' -o -name '*.dll' \) | sort)
    (( ${#bins[@]} )) || why=" no-binary"
    for f in ${bins[@]+"${bins[@]}"}; do check_binary "$plat" "$f"; done
    check_metadata "$plat" ${bins[@]+"${bins[@]}"}
    if [[ $plat == android ]]; then
      abis=$(ls "$TMP/android/jniLibs" 2>/dev/null | sort | tr '\n' ' ')
      [[ "$abis" == "$ANDROID_ABIS " ]] || why=" abis=[$abis]"
    fi
  fi
  if [[ -f "$archive" ]]; then scan local_path "$archive"; scan tar_meta "$archive"; fi
  [[ -z "$why" ]] || archive_ok=0
  if (( archive_ok )); then echo "OK   $plat/data.tgz"; else echo "FAIL $plat/data.tgz$found${why:+ ::$why}"; ok=0; fi
}

REPO=$(cd "$(dirname "$0")/../.." && pwd)
LINE=4.2 PLUGIN_DIR="" VERSION="" RUNTIME="" ENTRY="" ALLOW_LEGACY=0
while (( $# )); do
  case $1 in
    -h|--help) usage; exit 0 ;;
    --repo) value "$@"; REPO=$2; shift 2 ;;
    --line) value "$@"; LINE=$2; shift 2 ;;
    --plugin-dir) value "$@"; PLUGIN_DIR=$2; shift 2 ;;
    --version) value "$@"; VERSION=$2; shift 2 ;;
    --runtime) value "$@"; RUNTIME=$2; shift 2 ;;
    --entry) value "$@"; ENTRY=$2; shift 2 ;;
    --allow-legacy-metadata) ALLOW_LEGACY=1; shift ;;
    -*) die "unknown option $1 (--help)" ;;
    *) break ;;
  esac
done
for plat in "$@"; do [[ " $PLATFORMS " == *" $plat "* ]] || die "unknown platform '$plat' (one of: $PLATFORMS)"; done
(( $# )) || set -- $DEFAULT_PLATFORMS
PLUGIN_DIR=${PLUGIN_DIR:-$REPO/plugin/com.studycat/plugin.spine${LINE//./}}
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
