#!/bin/bash
# gate: tools/release-gate/gate.sh on each tracked archive against the fixed legacy identity v1.5.0 / 4.2 /
# plugin_spine (the tree's per-line identity is for the binaries it builds), one test per archive; then the per-line
# defaults the gate reads from the tree. Then the gate itself against archives of released tags (git show): 1.5.0's
# win32 archive (a 4.3 DLL) must fail on version, runtime and 4.3 markers as v1.5.0/4.2 and pass as v2.0.0/4.3,
# 1.5.0's mac-sim archive must fail as 4.3 for lacking the 4.3 markers, 1.3.0's and 1.2.5's (toolchain 4.4/4.5 strings
# beside 4.2) must pass as their version/4.2, and 1.5.0's other archives must pass. Last, every reason the gate
# can fail an archive for is proven to fire on a mutant: a tracked archive's copy under $SUITE_OUT/mutants with one
# defect written in (bytes rewritten, a file removed, or its binary swapped for one compiled at test time), gated
# under an identity its unmutated archive passes.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
GATE="$W/../../tools/release-gate/gate.sh"
PACKAGE=plugin/com.studycat.spine/plugin.spine
LEGACY_ENTRY=plugin_spine

for plat in android iphone mac-sim win32; do
  run_test "$plat/data.tgz" "$GATE" --repo "$SPINE_REPO" --version v1.5.0 --runtime 4.2 --entry "$LEGACY_ENTRY" "$plat"
done

# defaults line expected: the gate's "expect" line for the line's tree defaults
defaults() {
  local out
  out=$("$GATE" --repo "$SPINE_REPO" --line "$1" --plugin-dir "$SUITE_OUT/no-archives" mac-sim) || true
  printf '%s\n' "$out"
  [[ "$(head -1 <<<"$out")" == "expect $2 in $SUITE_OUT/no-archives" ]]
}
run_test "defaults 4.2 are v2.0.0/4.2/plugin_spine42" defaults 4.2 "v2.0.0 runtime 4.2 entry luaopen_plugin_spine42"
run_test "defaults 4.3 are v3.0.0/4.3/plugin_spine43" defaults 4.3 "v3.0.0 runtime 4.3 entry luaopen_plugin_spine43"

# tag_gate tag platform version runtime: the gate on the tag's archive, extracted into $SUITE_OUT/tags
tag_gate() {
  local dir="$SUITE_OUT/tags/$1"
  git -C "$SPINE_REPO" rev-parse -q --verify "$1^{commit}" >/dev/null || { echo "tag $1 not available (fetch tags)"; return 2; }
  mkdir -p "$dir/$2"
  git -C "$SPINE_REPO" show "$1:$PACKAGE/$2/data.tgz" >"$dir/$2/data.tgz" || return 2
  "$GATE" --plugin-dir "$dir" --version "$3" --runtime "$4" --entry "$LEGACY_ENTRY" "$2"
}

# rejects gate what platform version runtime reason...: the gate function (tag_gate, mutant_gate) fails (exit 1) and
# a FAIL line names every reason (an ERE)
rejects() {
  local out reason rc=0
  out=$("$1" "$2" "$3" "$4" "$5") || rc=$?
  printf '%s\n' "$out"
  (( rc == 1 )) || return 1
  shift 5
  for reason in "$@"; do grep -qE "^FAIL .*::.* $reason( |\$)" <<<"$out" || return 1; done
}

for plat in android iphone mac-sim; do
  run_test "1.5.0:$plat/data.tgz passes as v1.5.0/4.2" tag_gate 1.5.0 "$plat" v1.5.0 4.2
done
run_test "1.5.0:win32/data.tgz fails as v1.5.0/4.2 on version, runtime and 4.3-markers" rejects tag_gate 1.5.0 win32 v1.5.0 4.2 version runtime 4.3-markers
run_test "1.5.0:win32/data.tgz passes as v2.0.0/4.3" tag_gate 1.5.0 win32 v2.0.0 4.3
run_test "1.5.0:mac-sim/data.tgz fails as v1.5.0/4.3 on runtime and no-4.3-markers" rejects tag_gate 1.5.0 mac-sim v1.5.0 4.3 runtime no-4.3-markers
run_test "1.3.0:win32/data.tgz passes as v1.3.0/4.2" tag_gate 1.3.0 win32 v1.3.0 4.2
run_test "1.2.5:win32/data.tgz passes as v1.2.5/4.2" tag_gate 1.2.5 win32 v1.2.5 4.2

# mutant_gate mutation platform version runtime: the gate on the tracked platform archive with the mutation function
# run in its extracted tree, repacked into $SUITE_OUT/mutants/<mutation>; a tree the mutation empties is no archive
mutant_gate() {
  local dir="$SUITE_OUT/mutants/$1"
  rm -rf "$dir"
  mkdir -p "$dir/tree"
  tar xzf "$SPINE_REPO/$PACKAGE/$2/data.tgz" -C "$dir/tree" || return 2
  (cd "$dir/tree" && "$1") || return 2
  if [[ -n "$(ls -A "$dir/tree")" ]]; then
    mkdir -p "$dir/$2"
    tar czf "$dir/$2/data.tgz" -C "$dir/tree" . || return 2
  fi
  "$GATE" --plugin-dir "$dir" --version "$3" --runtime "$4" --entry "$LEGACY_ENTRY" "$2"
}

# rewrite file python: runs the python statements on b, the file's bytes as a bytearray, and writes b back
rewrite() {
  python3 - "$1" "$2" <<'PY'
import struct, sys
path, code = sys.argv[1:]
b = bytearray(open(path, 'rb').read())
exec(code)
open(path, 'wb').write(b)
PY
}

# synth_ios target: replaces libplugin_spine.a with one object compiled for the target that carries v1.5.0, 4.2 and
# the legacy entry, so only the target's architecture or platform can fail it
synth_ios() {
  printf '%s\n' '__attribute__((used)) const char *ids[] = {"v1.5.0", "4.2"};' \
    'int luaopen_plugin_spine(void *L) { return 0; }' | clang -x c -c -target "$1" -o ids.o - || return 1
  rm libplugin_spine.a && libtool -static -o libplugin_spine.a ids.o && rm ids.o
}

v7=jniLibs/armeabi-v7a/libplugin.spine.so
wrong_machine() { rewrite "$v7" "struct.pack_into('<H', b, 18, 3)"; }   # e_machine 3 = x86
align_4k() {
  rewrite jniLibs/arm64-v8a/libplugin.spine.so "
phoff, = struct.unpack_from('<Q', b, 32)
phes, phn = struct.unpack_from('<HH', b, 54)
for i in range(phn):
    if struct.unpack_from('<I', b, phoff + i * phes)[0] == 1: struct.pack_into('<Q', b, phoff + i * phes + 48, 4096)"
}
drop_x86() { rm -r jniLibs/x86; }
rename_entry() { rewrite "$v7" "b[:] = b.replace(b'luaopen_plugin_spine\\0', b'luaopen_plugin_spinX\\0')"; }
other_static_lib() { sed -i '' "s/'plugin_spine'/'plugin_other'/" metadata.lua; }
armv7_only() { synth_ios armv7-apple-ios10.0; }
simulator_slice() { synth_ios arm64-apple-ios14.0-simulator; }
arm64_only() { lipo -thin arm64 plugin_spine.dylib -output thin && mv thin plugin_spine.dylib; }
strip_signature() { codesign --remove-signature plugin_spine.dylib; }
no_dylib() { mv plugin_spine.dylib plugin_spine.txt; }
empty() { find . -mindepth 1 -delete; }
pe32_plus() { rewrite plugin_spine.dll "struct.pack_into('<H', b, struct.unpack_from('<I', b, 60)[0] + 24, 0x20b)"; }

run_test "mutant android: armeabi-v7a ELF machine x86 fails on arch" rejects mutant_gate wrong_machine android v1.5.0 4.2 arch
run_test "mutant android: arm64-v8a LOAD aligned 4 KB fails on 16k-align" rejects mutant_gate align_4k android v1.5.0 4.2 16k-align
run_test "mutant android: no x86 ABI fails on the ABI set" rejects mutant_gate drop_x86 android v1.5.0 4.2 'abis=\[arm64-v8a armeabi-v7a x86_64 \]'
run_test "mutant android: renamed luaopen symbol fails on entry" rejects mutant_gate rename_entry android v1.5.0 4.2 entry
run_test "mutant iphone: staticLibs naming no binary fails on staticLibs" rejects mutant_gate other_static_lib iphone v1.5.0 4.2 staticLibs
run_test "mutant iphone: armv7-only library fails on archs" rejects mutant_gate armv7_only iphone v1.5.0 4.2 archs
run_test "mutant iphone: arm64 simulator library fails on not-a-device-slice" rejects mutant_gate simulator_slice iphone v1.5.0 4.2 not-a-device-slice
run_test "mutant mac-sim: arm64-only dylib fails on archs" rejects mutant_gate arm64_only mac-sim v1.5.0 4.2 archs
run_test "mutant mac-sim: unsigned dylib fails on unsigned" rejects mutant_gate strip_signature mac-sim v1.5.0 4.2 unsigned
run_test "mutant mac-sim: archive without a binary fails on no-binary" rejects mutant_gate no_dylib mac-sim v1.5.0 4.2 no-binary
run_test "mutant mac-sim: no archive fails on missing" rejects mutant_gate empty mac-sim v1.5.0 4.2 missing
run_test "mutant win32: PE32+ DLL fails on not-PE32" rejects mutant_gate pe32_plus win32 v2.0.0 4.3 not-PE32
