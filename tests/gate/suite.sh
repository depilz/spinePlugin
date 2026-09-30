#!/bin/bash
# gate: tools/release-gate/gate.sh --line 4.2 on each tracked plugin.spine42 archive (the gate's default plugin dir,
# identity from the tree's Version.h), one test per platform, and --line 4.3 on each plugin.spine43 archive (ids
# prefixed spine43); then the per-line defaults the gate reads from the tree.
# Then the gate itself against legacy plugin.spine archives of released tags (git show): 1.5.0's
# win32 archive (a 4.3 DLL) must fail on version, runtime and 4.3 markers as v1.5.0/4.2 and pass as v2.0.0/4.3,
# 1.5.0's mac-sim archive must fail as 4.3 for lacking the 4.3 markers, 1.3.0's and 1.2.5's (toolchain 4.4/4.5 strings
# beside 4.2) must pass as their version/4.2, and 1.5.0's other archives must pass; every tag row passes the gate's
# legacy opt-out, and 1.5.0's iphone archive without it must fail on local-path and tar-meta; a checkout without the
# tag (a public clone) skips its rows, while a missing archive of a present tag fails. Last, every reason the
# gate can fail an archive for is proven to fire on a mutant: a tracked archive's copy under $SUITE_OUT/mutants with one
# defect written in (bytes rewritten, a file removed, or its binary swapped for one compiled at test time), repacked by
# tools/release/pack.sh and gated under the spine42 identity v2.0.0 / 4.2 / plugin_spine42 its unmutated archive
# passes; the tar-meta mutants rewrite the packed archive's headers under $SUITE_OUT/headers. Then an iphone library
# holding drive-letter look-alikes and an allowlisted toolchain path passes, and an unstripped iphone library whose
# debug info spells another runtime passes, while one with that literal in its data fails. Last, the sim-only
# platforms on plugin dirs built under $SUITE_OUT/sims: an iphone-sim copy of the tracked iphone archive, a linux-sim
# Lua stub and a stub packed twice from differently stamped copies pass, and a rebuilt iphone-sim library, a stub with
# another version, a stub named for another line and a stub naming a temporary path fail. Finally, the tools' own
# guards: pack.sh refuses an OUT inside a packed member, a gate.sh copy whose LOCAL_PATH_ALLOW overlaps a user path
# fails, and the gate with no platform argument checks exactly the six default platforms and fails a copy missing one.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
GATE="$W/../../tools/release-gate/gate.sh"
PACK="$W/../../tools/release/pack.sh"
PACKAGE=plugin/com.studycat/plugin.spine42
ENTRY=plugin_spine42
LEGACY_PACKAGE=plugin/com.studycat.spine/plugin.spine
LEGACY_ENTRY=plugin_spine

for plat in android iphone iphone-sim mac-sim win32-sim linux-sim; do
  run_test "$plat/data.tgz" "$GATE" --repo "$SPINE_REPO" --line 4.2 "$plat"
done
for plat in android iphone iphone-sim mac-sim win32-sim linux-sim; do
  run_test "spine43 $plat/data.tgz" "$GATE" --repo "$SPINE_REPO" --line 4.3 "$plat"
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

# tag_gate tag platform version runtime: the gate with the legacy opt-out on the tag's archive: released archives
# predate local-path and tar-meta
tag_gate() { default_tag_gate "$@" --allow-legacy-metadata; }

# default_tag_gate tag platform version runtime [flag...]: the gate (with the flags) on the tag's archive, extracted
# into $SUITE_OUT/tags
default_tag_gate() {
  local dir="$SUITE_OUT/tags/$1"
  git -C "$SPINE_REPO" rev-parse -q --verify "$1^{commit}" >/dev/null || { echo "tag $1 not available (fetch tags)"; return 2; }
  mkdir -p "$dir/$2"
  git -C "$SPINE_REPO" show "$1:$LEGACY_PACKAGE/$2/data.tgz" >"$dir/$2/data.tgz" || return 2
  "$GATE" --plugin-dir "$dir" --version "$3" --runtime "$4" --entry "$LEGACY_ENTRY" "${@:5}" "$2"
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

# tag_test tag test command...: run_test, or skip the test when the checkout lacks the tag
tag_test() {
  if git -C "$SPINE_REPO" rev-parse -q --verify "$1^{commit}" >/dev/null; then
    run_test "${@:2}"
  else
    skip "$2" "needs tag $1 from the private history"
  fi
}

for plat in android iphone mac-sim; do
  tag_test 1.5.0 "1.5.0:$plat/data.tgz passes as v1.5.0/4.2" tag_gate 1.5.0 "$plat" v1.5.0 4.2
done
tag_test 1.5.0 "1.5.0:win32/data.tgz fails as v1.5.0/4.2 on version, runtime and 4.3-markers" rejects tag_gate 1.5.0 win32 v1.5.0 4.2 version runtime 4.3-markers
tag_test 1.5.0 "1.5.0:win32/data.tgz passes as v2.0.0/4.3" tag_gate 1.5.0 win32 v2.0.0 4.3
tag_test 1.5.0 "1.5.0:mac-sim/data.tgz fails as v1.5.0/4.3 on runtime and no-4.3-markers" rejects tag_gate 1.5.0 mac-sim v1.5.0 4.3 runtime no-4.3-markers
tag_test 1.3.0 "1.3.0:win32/data.tgz passes as v1.3.0/4.2" tag_gate 1.3.0 win32 v1.3.0 4.2
tag_test 1.2.5 "1.2.5:win32/data.tgz passes as v1.2.5/4.2" tag_gate 1.2.5 win32 v1.2.5 4.2
tag_test 1.5.0 "1.5.0:iphone/data.tgz without the legacy opt-out fails on local-path and tar-meta" rejects default_tag_gate 1.5.0 iphone v1.5.0 4.2 local-path tar-meta

# mutant_gate mutation platform version runtime: the gate on the tracked platform archive with the mutation function
# run in its extracted tree, repacked by pack.sh into $SUITE_OUT/mutants/<mutation>; a tree the mutation empties is no
# archive
mutant_gate() {
  local dir="$SUITE_OUT/mutants/$1"
  rm -rf "$dir"
  mkdir -p "$dir/tree"
  tar xzf "$SPINE_REPO/$PACKAGE/$2/data.tgz" -C "$dir/tree" || return 2
  (cd "$dir/tree" && "$1") || return 2
  if [[ -n "$(ls -A "$dir/tree")" ]]; then
    mkdir -p "$dir/$2"
    "$PACK" --mtime 0 "$dir/tree" "$dir/$2/data.tgz" || return 2
  fi
  "$GATE" --plugin-dir "$dir" --version "$3" --runtime "$4" --entry "$ENTRY" "$2"
}

# header_gate mutation platform version runtime: the gate on the tracked platform archive repacked by pack.sh into
# $SUITE_OUT/headers/<mutation>, whose headers the mutation function (run in <platform>/) then rewrites with retar
header_gate() {
  local dir="$SUITE_OUT/headers/$1"
  rm -rf "$dir"
  mkdir -p "$dir/tree" "$dir/$2"
  tar xzf "$SPINE_REPO/$PACKAGE/$2/data.tgz" -C "$dir/tree" || return 2
  "$PACK" --mtime 0 "$dir/tree" "$dir/$2/data.tgz" || return 2
  (cd "$dir/$2" && "$1") || return 2
  "$GATE" --plugin-dir "$dir" --version "$3" --runtime "$4" --entry "$ENTRY" "$2"
}

# rewrite file python: runs the python statements on b, the file's bytes as a bytearray, and writes b back; fails when
# the statements change nothing or change the file's length, so a mutant carries exactly its one in-place defect
rewrite() {
  python3 - "$1" "$2" <<'PY'
import struct, sys
path, code = sys.argv[1:]
b = bytearray(open(path, 'rb').read())
original = bytes(b)
exec(code)
if b == original: sys.exit(f'rewrite {path}: no change')
if len(b) != len(original): sys.exit(f'rewrite {path}: length {len(original)} -> {len(b)}')
open(path, 'wb').write(b)
PY
}

# retar python: rewrites data.tgz as a pax archive after running the python statements on ms, its members as a list of
# (TarInfo, bytes or None) pairs, so a mutant carries header metadata pack.sh never writes
retar() {
  python3 - "$1" <<'PY'
import gzip, io, struct, sys, tarfile
with tarfile.open('data.tgz') as tar:
    ms = [(m, tar.extractfile(m).read() if m.isfile() else None) for m in tar.getmembers()]
exec(sys.argv[1])
out = io.BytesIO()
with tarfile.open(fileobj=out, mode='w', format=tarfile.PAX_FORMAT) as tar:
    for m, d in ms: tar.addfile(m, io.BytesIO(d) if d is not None else None)
open('data.tgz', 'wb').write(gzip.compress(out.getvalue()))
PY
}

# synth_ios target [cflags [line...]]: replaces libplugin_spine42.a with one object compiled for the target (with the
# cflags) from the lines plus a part that carries v2.0.0, 4.2 and the spine42 entry, so only the target's architecture
# or platform, or the lines, can fail it
synth_ios() {
  local target=$1 cflags=${2:-}
  shift $(( $# < 2 ? $# : 2 ))
  printf '%s\n' "$@" '__attribute__((used)) const char *ids[] = {"v2.0.0", "4.2"};' \
    'int luaopen_plugin_spine42(void *L) { return 0; }' | clang -x c -c -target "$target" $cflags -o ids.o - || return 1
  rm libplugin_spine42.a && libtool -static -o libplugin_spine42.a ids.o && rm ids.o
}

v7=jniLibs/armeabi-v7a/libplugin.spine42.so
wrong_machine() { rewrite "$v7" "struct.pack_into('<H', b, 18, 3)"; }   # e_machine 3 = x86
align_4k() {
  rewrite jniLibs/arm64-v8a/libplugin.spine42.so "
phoff, = struct.unpack_from('<Q', b, 32)
phes, phn = struct.unpack_from('<HH', b, 54)
for i in range(phn):
    if struct.unpack_from('<I', b, phoff + i * phes)[0] == 1: struct.pack_into('<Q', b, phoff + i * phes + 48, 4096)"
}
drop_x86() { rm -r jniLibs/x86; }
rename_entry() { rewrite "$v7" "b[:] = b.replace(b'luaopen_plugin_spine42\\0', b'luaopen_plugin_spinX42\\0')"; }
other_static_lib() { sed -i '' "s/'plugin_spine42'/'plugin_other'/" metadata.lua; }
armv7_only() { synth_ios armv7-apple-ios10.0; }
simulator_slice() { synth_ios arm64-apple-ios14.0-simulator; }
arm64_only() { lipo -thin arm64 plugin_spine42.dylib -output thin && mv thin plugin_spine42.dylib; }
strip_signature() { codesign --remove-signature plugin_spine42.dylib; }
no_dylib() { mv plugin_spine42.dylib plugin_spine42.txt; }
empty() { find . -mindepth 1 -delete; }
pe32_plus() { rewrite plugin_spine42.dll "struct.pack_into('<H', b, struct.unpack_from('<I', b, 60)[0] + 24, 0x20b)"; }
# user_path file: the file's first shared/Lua_Spine.cpp path rewritten, same length, to one under /Users/x/
user_path() { rewrite "$1" "p = b'shared/Lua_Spine.cpp'; i = b.index(p); b[i:i + len(p)] = (b'/Users/x/' + p)[:len(p)]"; }
# pdb_path prefix: the DLL's RSDS PDB path rewritten, same length, to start with the prefix (a python bytes literal)
pdb_path() { rewrite plugin_spine42.dll "i = b.index(b'RSDS') + 24; j = b.index(b'\\0', i); b[i:j] = ($1 + b[i:j])[:j - i]"; }
so_user_path() { user_path "$v7"; }
slice_user_path() { user_path plugin_spine42.dylib; }
pdb_user_path() { pdb_path 'b"C:\\Users\\x\\"'; }
pdb_unc_path() { pdb_path 'b"\\\\host\\share\\"'; }
owned() { retar "for m, d in ms: m.uid, m.uname = 501, 'runner'"; }
xattr_record() { retar "ms[0][0].pax_headers['SCHILY.xattr.com.apple.provenance'] = 'x'"; }
# apple_double: a ._ member ahead of the first, an AppleDouble file with an empty attribute list (bsdtar refuses to
# extract a malformed one)
apple_double() {
  retar "d = struct.pack('>II16sH6I34x4s4I12x2H', 0x51607, 0x20000, b'Mac OS X', 2, 9, 50, 70, 2, 120, 0, b'ATTR', 0, 120, 120, 0, 0, 0)
a = tarfile.TarInfo('._' + ms[0][0].name); a.size = len(d); ms.insert(0, (a, d))"
}

run_test "mutant android: armeabi-v7a ELF machine x86 fails on arch" rejects mutant_gate wrong_machine android v2.0.0 4.2 arch
run_test "mutant android: arm64-v8a LOAD aligned 4 KB fails on 16k-align" rejects mutant_gate align_4k android v2.0.0 4.2 16k-align
run_test "mutant android: no x86 ABI fails on the ABI set" rejects mutant_gate drop_x86 android v2.0.0 4.2 'abis=\[arm64-v8a armeabi-v7a x86_64 \]'
run_test "mutant android: renamed luaopen symbol fails on entry" rejects mutant_gate rename_entry android v2.0.0 4.2 entry
run_test "mutant iphone: staticLibs naming no binary fails on staticLibs" rejects mutant_gate other_static_lib iphone v2.0.0 4.2 staticLibs
run_test "mutant iphone: armv7-only library fails on archs" rejects mutant_gate armv7_only iphone v2.0.0 4.2 archs
run_test "mutant iphone: arm64 simulator library fails on not-a-device-slice" rejects mutant_gate simulator_slice iphone v2.0.0 4.2 not-a-device-slice
run_test "mutant mac-sim: arm64-only dylib fails on archs" rejects mutant_gate arm64_only mac-sim v2.0.0 4.2 archs
run_test "mutant mac-sim: unsigned dylib fails on unsigned" rejects mutant_gate strip_signature mac-sim v2.0.0 4.2 unsigned
run_test "mutant mac-sim: archive without a binary fails on no-binary" rejects mutant_gate no_dylib mac-sim v2.0.0 4.2 no-binary
run_test "mutant mac-sim: no archive fails on missing" rejects mutant_gate empty mac-sim v2.0.0 4.2 missing
run_test "mutant win32-sim: PE32+ DLL fails on not-PE32" rejects mutant_gate pe32_plus win32-sim v2.0.0 4.2 not-PE32
run_test "mutant android: armeabi-v7a source path under /Users/x/ fails on local-path" rejects mutant_gate so_user_path android v2.0.0 4.2 local-path
run_test "mutant mac-sim: one slice's source path under /Users/x/ fails on local-path" rejects mutant_gate slice_user_path mac-sim v2.0.0 4.2 local-path
run_test "mutant win32-sim: PDB path in a Windows user folder fails on local-path" rejects mutant_gate pdb_user_path win32-sim v2.0.0 4.2 local-path
run_test "mutant win32-sim: PDB path on a UNC share fails on local-path" rejects mutant_gate pdb_unc_path win32-sim v2.0.0 4.2 local-path
run_test "mutant win32-sim: members owned by uid 501 runner fail on tar-meta" rejects header_gate owned win32-sim v2.0.0 4.2 tar-meta
run_test "mutant win32-sim: member with an xattr pax record fails on tar-meta" rejects header_gate xattr_record win32-sim v2.0.0 4.2 tar-meta
run_test "mutant win32-sim: ._ AppleDouble member fails on tar-meta" rejects header_gate apple_double win32-sim v2.0.0 4.2 tar-meta

device=arm64-apple-ios14.0
unmapped_debug() { synth_ios "$device" -g; }   # DWARF comp_dir: the physical $SUITE_OUT tree, /private/… on macOS
user_before_allowed() { synth_ios "$device" '' '__attribute__((used)) const char *p = "/Users/x/Volumes/Android/buildbot/x";'; }
lookalikes() {
  synth_ios "$device" '' '__attribute__((used)) const char *s[] = {"V:\\:e:q:", "X:\\:l:p:t:x:", "f:\\~V", "/Volumes/Android/buildbot/x"};'
}
# debug info names the source file 4.1: a standalone 4.1 string only in the object's DWARF, compiled in "."
dwarf_runtime() { synth_ios "$device" '-g -ffile-compilation-dir=.' '#line 1 "4.1"'; }
data_runtime() { synth_ios "$device" -g '__attribute__((used)) const char *rt = "4.1";'; }

run_test "mutant iphone: unmapped debug info fails on local-path" rejects mutant_gate unmapped_debug iphone v2.0.0 4.2 local-path
run_test "mutant iphone: allowlisted path after /Users/x/ fails on local-path" rejects mutant_gate user_before_allowed iphone v2.0.0 4.2 local-path
run_test "iphone: library holding drive-letter look-alikes and the NDK build path passes as v2.0.0/4.2" mutant_gate lookalikes iphone v2.0.0 4.2
run_test "iphone: unstripped library whose debug info holds 4.1 passes as v2.0.0/4.2" mutant_gate dwarf_runtime iphone v2.0.0 4.2
run_test "mutant iphone: unstripped library with 4.1 in its data fails on runtime" rejects mutant_gate data_runtime iphone v2.0.0 4.2 runtime

# sim_gate setup platform version runtime: the gate on the plugin dir $SUITE_OUT/sims/<setup> holding the archives the
# setup function writes (run in that dir), plus the tracked iphone archive an iphone-sim one is compared with
sim_gate() {
  local dir="$SUITE_OUT/sims/$1"
  rm -rf "$dir"
  mkdir -p "$dir/iphone"
  [[ $2 != iphone-sim ]] || cp "$SPINE_REPO/$PACKAGE/iphone/data.tgz" "$dir/iphone/" || return 2
  (cd "$dir" && "$1") || return 2
  "$GATE" --plugin-dir "$dir" --version "$3" --runtime "$4" --entry "$ENTRY" "$2"
}

# sim_archive platform source mutation: <platform>/data.tgz holding the tracked source platform archive's tree with the
# mutation function (or true) run in it
sim_archive() {
  mkdir -p tree "$1"
  tar xzf "$SPINE_REPO/$PACKAGE/$2/data.tgz" -C tree && (cd tree && "$3") && "$PACK" --mtime 0 tree "$1/data.tgz"
}

# stub version entry [line...]: linux-sim/data.tgz holding the Lua stub <entry>.lua that declares the version (and has
# the lines)
stub() {
  mkdir -p tree linux-sim
  printf '%s\n' "local lib = require('CoronaLibrary'):new{ name='spine', publisherId='com.studycat', version='$1' }" \
    "${@:3}" 'return lib' >"tree/$2.lua" && "$PACK" --mtime 0 tree linux-sim/data.tgz
}

# packed_twice: the stub's archive, which must equal the one pack.sh makes of a copy of its tree with another mtime,
# an xattr and a ._ sibling
packed_twice() {
  stub v2.0.0 "$ENTRY" && cp -R tree copy && touch -t 200101010000 "copy/$ENTRY.lua" &&
    xattr -w com.studycat.test 1 "copy/$ENTRY.lua" && printf x >"copy/._$ENTRY.lua" &&
    "$PACK" --mtime 0 copy copy.tgz && cmp linux-sim/data.tgz copy.tgz
}

iphone_sim_copy() { sim_archive iphone-sim iphone true; }
iphone_sim_rebuilt() { sim_archive iphone-sim iphone simulator_slice; }
linux_stub() { stub v2.0.0 "$ENTRY"; }
linux_stub_old() { stub v1.4.0 "$ENTRY"; }
linux_stub_other_line() { stub v2.0.0 plugin_spine43; }
linux_stub_tmp_path() { stub v2.0.0 "$ENTRY" '-- built in /private/tmp/x'; }

run_test "iphone-sim: copy of the iphone archive passes as v2.0.0/4.2" sim_gate iphone_sim_copy iphone-sim v2.0.0 4.2
run_test "iphone-sim: rebuilt simulator library fails on not-a-device-slice and not-iphone-copy" rejects sim_gate iphone_sim_rebuilt iphone-sim v2.0.0 4.2 not-a-device-slice not-iphone-copy
run_test "linux-sim: stub declaring v2.0.0 passes as v2.0.0" sim_gate linux_stub linux-sim v2.0.0 4.2
run_test "linux-sim: stub declaring v1.4.0 fails on version" rejects sim_gate linux_stub_old linux-sim v2.0.0 4.2 version
run_test "linux-sim: stub named for another line fails on stub" rejects sim_gate linux_stub_other_line linux-sim v2.0.0 4.2 stub
run_test "linux-sim: stub naming /private/tmp/x fails on local-path" rejects sim_gate linux_stub_tmp_path linux-sim v2.0.0 4.2 local-path
run_test "packer: stub tree and a copy with another mtime, an xattr and a ._ sibling pack alike and pass as v2.0.0" sim_gate packed_twice linux-sim v2.0.0 4.2

# pack_refuses tree out [member...]: pack.sh exits 2 on the arguments
pack_refuses() {
  local rc=0
  "$PACK" --mtime 0 "$@" || rc=$?
  (( rc == 2 ))
}

# self_pack: pack.sh exits 2 and writes nothing when OUT is a packed member, lies under one, or is a stale OUT inside a
# TREE packed without MEMBERs; an OUT beside the members (android/build.sh's shape) packs
self_pack() {
  local t="$SUITE_OUT/self-pack"
  rm -rf "$t" && mkdir -p "$t/jniLibs" && printf x >"$t/metadata.lua" && printf y >"$t/jniLibs/lib.so" || return 2
  "$PACK" --mtime 0 "$t" "$t/data.tgz" metadata.lua jniLibs && [[ -f "$t/data.tgz" ]] || return 1
  pack_refuses "$t" "$t/jniLibs/data.tgz" metadata.lua jniLibs && [[ ! -e "$t/jniLibs/data.tgz" ]] &&
    pack_refuses "$t" "$t/metadata.lua" metadata.lua && [[ "$(cat "$t/metadata.lua")" == x ]] &&
    cp "$t/data.tgz" "$t/stale.tgz" && pack_refuses "$t" "$t/data.tgz" && cmp "$t/data.tgz" "$t/stale.tgz"
}

# overlap_gate entry platform: a copy of gate.sh whose LOCAL_PATH_ALLOW also holds the entry, run on the tracked archive;
# the allowlist guard must fail it (exit 1) on local-path, the scan naming the overlap
overlap_gate() {
  local copy="$SUITE_OUT/overlap/gate.sh" out rc=0
  mkdir -p "$SUITE_OUT/overlap"
  awk -v e="$1" '{ print } /^LOCAL_PATH_ALLOW=\(/ { print "  " e }' "$GATE" >"$copy" && ! cmp -s "$GATE" "$copy" || return 2
  out=$(bash "$copy" --repo "$SPINE_REPO" --line 4.2 "$2") || rc=$?
  printf '%s\n' "$out"
  (( rc == 1 )) && grep -qE '^FAIL .*local-path=\[scan failed: LOCAL_PATH_ALLOW overlaps a user path\].*:: *local-path( |$)' <<<"$out"
}

# default_platforms [plugin-dir]: the gate with no platform argument on the tracked spine42 package (or the plugin dir):
# one archive line for each of the six default platforms, in order, and the gate's exit status
DEFAULT_ARCHIVES="android iphone iphone-sim mac-sim win32-sim linux-sim"
default_platforms() {
  local out rc=0
  out=$("$GATE" --repo "$SPINE_REPO" --line 4.2 ${1:+--plugin-dir "$1"}) || rc=$?
  printf '%s\n' "$out"
  [[ "$(sed -nE 's#^(OK  |FAIL) ([a-z0-9-]+)/data\.tgz( .*)?$#\2#p' <<<"$out" | tr '\n' ' ')" == "$DEFAULT_ARCHIVES " ]] || return 3
  return $rc
}
# without_win32_sim: default_platforms on a copy of the spine42 package without its win32-sim archive, which must fail
# (exit 1) on missing
without_win32_sim() {
  local dir="$SUITE_OUT/defaults/plugin" out rc=0
  rm -rf "$dir" && mkdir -p "$dir" && cp -R "$SPINE_REPO/$PACKAGE/" "$dir/" && rm -r "$dir/win32-sim" || return 2
  out=$(default_platforms "$dir") || rc=$?
  printf '%s\n' "$out"
  (( rc == 1 )) && grep -qE '^FAIL win32-sim/data\.tgz :: *missing$' <<<"$out"
}

run_test "packer: OUT equal to or under a packed member exits 2 and writes nothing; OUT beside the members packs" self_pack
run_test "mutant gate.sh: LOCAL_PATH_ALLOW entry /Users/runner/ fails on local-path (allowlist overlap)" overlap_gate /Users/runner/ linux-sim
run_test "no platform argument gates the six default platforms, each passing" default_platforms
run_test "no platform argument on a copy without win32-sim fails on missing" without_win32_sim
