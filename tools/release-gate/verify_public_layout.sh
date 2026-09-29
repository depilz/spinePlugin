#!/bin/bash
# Release gate for the Solar2D Free Plugin Directory layout (solar2d/com.studycat-plugin.spine: plugins/2020.2600/<platform>/...).
# Usage: verify_public_layout.sh <dir containing android/ iphone/ iphone-sim/ mac-sim/ win32-sim/ linux-sim/> <expected version, e.g. v1.2.6> [reference layout dir]
# Read-only on its inputs. Exit 0 = all checks pass, 1 = a check failed, 2 = usage error.
usage() { sed -n '2,3p' "$0" | sed 's/^# \{0,1\}//'; }
case ${1:-} in -h|--help) usage; exit 0;; esac
[[ $# -ge 2 ]] || { usage >&2; exit 2; }
D=$1; WANT=$2; REF=${3:-}; fail=0
ok()   { echo "OK   $*"; }
bad()  { echo "FAIL $*"; fail=1; }
ver()  { strings -a "$1" | grep -x -E 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -u | tr '\n' ' ' | sed 's/ $//'; }
rt()   { strings -a -n 3 "$1" | grep -x -E '4\.[0-9]' | sort -u | tr '\n' ' ' | sed 's/ $//'; }
m43()  { strings -a "$1" | grep -c -E 'SlotPose|SliderData|SliderTimeline'; }
chk()  { local f=$1 label=$2; [[ -f $f ]] || { bad "$label: missing $f"; return 1; }
         local v=$(ver "$f") r=$(rt "$f") m=$(m43 "$f")
         [[ "$v" == "$WANT" ]] && [[ " $r " == *" 4.2 "* ]] && [[ $m == 0 ]] && ok "$label version=[$v] runtime=[$r]" || bad "$label version=[$v] (want $WANT) runtime=[$r] 4.3-markers=$m"; }
for p in android iphone iphone-sim mac-sim win32-sim linux-sim; do [[ -d $D/$p ]] || bad "platform dir $p missing"; done
for abi in armeabi-v7a arm64-v8a x86 x86_64; do
  f=$D/android/jniLibs/$abi/libplugin.spine.so; chk "$f" "android/$abi" || continue
  a=$(python3 - "$f" <<'PY'
import struct,sys
b=open(sys.argv[1],'rb').read(); c=b[4]; le='<'
if c==2: phoff,=struct.unpack_from(le+'Q',b,32); phes,phn=struct.unpack_from(le+'HH',b,54); fmt=le+'IIQQQQQQ'; ia=7
else: phoff,=struct.unpack_from(le+'I',b,28); phes,phn=struct.unpack_from(le+'HH',b,42); fmt=le+'IIIIIIII'; ia=7
al=[]
for i in range(phn):
    e=struct.unpack_from(fmt,b,phoff+i*phes)
    if e[0]==1: al.append(e[ia] if c==2 else e[7])
print(min(al))
PY
); if [[ $abi == arm64-v8a || $abi == x86_64 ]]; then [[ $a -ge 16384 ]] && ok "android/$abi LOAD align=$a (16 KB pages, required for 64-bit ABIs)" || bad "android/$abi LOAD align=$a < 16384"; else echo "INFO android/$abi LOAD align=$a (32-bit ABI, 16 KB not required)"; fi
done
chk "$D/iphone/libplugin_spine.a" "iphone"; lipo -info "$D/iphone/libplugin_spine.a" 2>/dev/null | sed 's/^/     /'
chk "$D/iphone-sim/libplugin_spine.a" "iphone-sim"
chk "$D/mac-sim/plugin_spine.dylib" "mac-sim"
archs=$(lipo -archs "$D/mac-sim/plugin_spine.dylib" 2>/dev/null); [[ " $archs " == *" x86_64 "* && " $archs " == *" arm64 "* ]] && ok "mac-sim archs=[$archs]" || bad "mac-sim archs=[$archs] (need x86_64 arm64)"
codesign -v "$D/mac-sim/plugin_spine.dylib" 2>/dev/null && ok "mac-sim code signature valid ($(codesign -dv "$D/mac-sim/plugin_spine.dylib" 2>&1 | grep -o 'Signature=.*'))" || bad "mac-sim not signed (the Simulator refuses unsigned plugin dylibs)"
chk "$D/win32-sim/plugin_spine.dll" "win32-sim"; file "$D/win32-sim/plugin_spine.dll" | grep -q "PE32 executable" && ok "win32-sim is PE32 (x86) like 1.2.5" || bad "win32-sim is not a PE32 x86 DLL: $(file -b "$D/win32-sim/plugin_spine.dll")"
if [[ -n $REF ]]; then for m in android/metadata.lua iphone/metadata.lua iphone-sim/metadata.lua linux-sim/plugin_spine.lua; do
  [[ -f $REF/$m ]] || continue; cmp -s "$D/$m" "$REF/$m" && ok "$m unchanged vs reference" || bad "$m differs from reference"; done; fi
exit $fail
