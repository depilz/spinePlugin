#!/bin/bash
# Release gate for one plugin artifact set (Solar2DPlugins data.tgz or Directory repo layout).
# Read-only on its inputs. Exit 0 = all checks pass, 1 = a check failed, 2 = usage error.
# usage: verify_release2.sh <dir-with-platform-subdirs> <plugin.name> <vX.Y.Z> <runtime 4.2|4.3>
#   <dir> contains <platform>/data.tgz (Solar2DPlugins / repo layout) or <platform>/<files> (Directory repo layout).
# Env: PLATS (default "android iphone iphone-sim mac-sim win32-sim")
# Checks per platform: archive present; every binary reports the plugin version and embeds SPINE_VERSION_STRING;
# the entry point is luaopen_<plugin name with '.'->'_'>; metadata staticLibs names the shipped library;
# android has 4 ABIs; iphone is a device slice, iphone-sim a simulator slice; mac-sim is universal and signed.
set -u
usage() { sed -n '4,9p' "$0" | sed 's/^# \{0,1\}//'; }
case ${1:-} in -h|--help) usage; exit 0;; esac
[[ $# -ge 4 ]] || { usage >&2; exit 2; }
D="$1"; PLUGIN="$2"; WANT_VER="$3"; WANT_RT="$4"
SYM="luaopen_$(echo "$PLUGIN" | tr . _)"
T=$(mktemp -d); fail=0
say() { echo "$1"; if [[ "$1" == FAIL* ]]; then fail=1; fi; return 0; }
echo "expect $PLUGIN $WANT_VER runtime $WANT_RT entry $SYM"
for plat in ${PLATS:-android iphone iphone-sim mac-sim win32-sim}; do
  mkdir -p "$T/$plat"
  if [ -f "$D/$plat/data.tgz" ]; then tar xzf "$D/$plat/data.tgz" -C "$T/$plat"
  elif [ -d "$D/$plat" ]; then cp -R "$D/$plat/." "$T/$plat/"
  else say "FAIL $plat: no archive"; continue; fi
  bins=$(find "$T/$plat" -type f \( -name '*.so' -o -name '*.a' -o -name '*.dylib' -o -name '*.dll' \))
  [ -z "$bins" ] && say "FAIL $plat: archive has no binary"
  for f in $bins; do
    rel=${f#$T/}
    v=$(strings -a "$f" | grep -x -E 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -u | tr '\n' ' ')
    rt=$(strings -a -n 3 "$f" | grep -x -E '[0-9]\.[0-9]' | sort -u | tr '\n' ' ')
    case "$f" in *.dll|*.so) ent=$(strings -a "$f" | grep -x -c "$SYM");; *) ent=$(nm -gU "$f" 2>/dev/null | grep -c " _\{0,1\}$SYM\$");; esac  # ELF/PE: export name string
    st=OK; why=""
    [[ "$v" == "$WANT_VER " ]] || { st=FAIL; why="$why version"; }
    [[ " $rt" == *" $WANT_RT "* ]] || { st=FAIL; why="$why runtime"; }
    [ "$ent" -ge 1 ] || { st=FAIL; why="$why entry"; }
    extra=""
    case "$plat" in
      iphone|iphone-sim)
        plats=$(otool -l "$f" 2>/dev/null | awk '/LC_BUILD_VERSION/{b=1} b&&/platform/{print $2; b=0} /LC_VERSION_MIN_IPHONEOS/{print "2"}' | sort -u | tr '\n' ' ')
        extra="platform-ids=[$plats]"   # 2 = iOS device, 7 = iOS simulator
        if [ "$plat" = iphone-sim ] && [[ " $plats" != *" 7 "* ]]; then st=FAIL; why="$why not-a-simulator-slice"; fi
        if [ "$plat" = iphone ] && [[ " $plats" != *" 2 "* ]]; then st=FAIL; why="$why not-a-device-slice"; fi;;
      mac-sim)
        archs=$(lipo -archs "$f" 2>/dev/null); sig=$(codesign -dv "$f" 2>&1 | grep -c 'Signature\|CodeDirectory')
        extra="archs=[$archs] signed=$sig"
        [[ "$archs" == *arm64* && "$archs" == *x86_64* ]] || { st=FAIL; why="$why archs"; }
        [ "$sig" -ge 1 ] || { st=FAIL; why="$why unsigned"; };;
    esac
    say "$st $rel version=[$v] runtime=[$rt] entry=$ent $extra${why:+ ::$why}"
  done
  if [ -f "$T/$plat/metadata.lua" ]; then
    libs=$(sed -n 's/.*staticLibs *= *{ *\(.*\) *}.*/\1/p' "$T/$plat/metadata.lua" | tr -d "\"' ," )
    have=$(for f in $bins; do b=$(basename "$f"); b=${b%.*}; echo "${b#lib}"; done | sort -u | tr '\n' ' ')
    ok=FAIL; for l in $libs; do [[ " $have" == *" ${l#lib} "* ]] && ok=OK; done
    say "$ok $plat/metadata.lua staticLibs=[$libs] binaries=[$have]"
  fi
  if [ "$plat" = android ]; then abis=$(ls "$T/android/jniLibs" 2>/dev/null | tr '\n' ' '); [ "$(echo $abis | wc -w)" -eq 4 ] && say "OK android ABIs: $abis" || say "FAIL android ABIs: $abis"; fi
done
rm -rf "$T"; exit $fail
