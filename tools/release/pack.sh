#!/bin/bash
# Deterministic data.tgz packer: the same tree and epoch give the same bytes on any host.
# usage: tools/release/pack.sh --mtime EPOCH TREE OUT.tgz [MEMBER...]
# Packs the MEMBERs (paths relative to TREE, a directory recursing) or, with none, everything under TREE, into OUT.tgz,
# which must lie outside the packed members (an OUT equal to or under one exits 2). Skips every `._*` entry; only
# regular files and directories are allowed.
# Output: POSIX ustar without pax records, entries sorted by path with no leading ./, directories as entries, every
# mtime EPOCH, uid/gid 0, empty uname/gname; gzip level 9 with MTIME 0 and no file name.
# Modes: directories 0755; every file 0755 when the packed set holds a directory (the android layout: metadata.lua
# and jniLibs/<abi>/*.so); otherwise .so and .dylib files 0755 and all other files 0644.
# Exit 0 = OUT.tgz written, 2 = usage or input error (nothing written).
set -uo pipefail

usage() { sed -n '3,11s/^# //p' "$0"; }
die() { echo "pack.sh: $*" >&2; exit 2; }

[[ "${1:-}" == --help || "${1:-}" == -h ]] && { usage; exit 0; }
[[ "${1:-}" == --mtime ]] || { usage >&2; exit 2; }
[[ "${2:-}" =~ ^[0-9]+$ ]] || die "--mtime needs an integer epoch"
[[ $# -ge 4 ]] || { usage >&2; exit 2; }
[[ -d "$3" ]] || die "no tree directory $3"

python3 - "$@" <<'PY' || exit 2
import gzip, io, os, stat, sys, tarfile

_, epoch, tree, out, *members = sys.argv[1:]
epoch = int(epoch)

def fail(msg):
    sys.stderr.write(f"pack.sh: {msg}\n")
    sys.exit(2)

def walk(rel):
    if os.path.basename(rel).startswith("._"):
        return
    st = os.lstat(os.path.join(tree, rel))
    if stat.S_ISDIR(st.st_mode):
        yield rel, True
        for name in os.listdir(os.path.join(tree, rel)):
            yield from walk(os.path.join(rel, name))
    elif stat.S_ISREG(st.st_mode):
        yield rel, False
    else:
        fail(f"{rel} is neither a regular file nor a directory")

roots = [os.path.normpath(m) for m in members] or os.listdir(tree)
out_real = os.path.realpath(out)
for root in roots:
    if root in (".", "..") or root.startswith("../") or os.path.isabs(root) or not os.path.lexists(os.path.join(tree, root)):
        fail(f"no member {root} in {tree}")
    member = os.path.realpath(os.path.join(tree, root))
    if out_real == member or out_real.startswith(member + os.sep):
        fail(f"{out} lies in the packed member {root}")
entries = dict(e for root in roots for e in walk(root))
if not entries:
    fail(f"nothing to pack in {tree}")
layout_has_dirs = any(entries.values())

def mode(name, is_dir):
    if is_dir or layout_has_dirs or name.endswith((".so", ".dylib")):
        return 0o755
    return 0o644

def header(name, is_dir):
    info = tarfile.TarInfo(name)
    info.type = tarfile.DIRTYPE if is_dir else tarfile.REGTYPE
    info.size = 0 if is_dir else os.path.getsize(os.path.join(tree, name))
    info.mode = mode(name, is_dir)
    info.mtime = epoch
    info.uid = info.gid = 0
    info.uname = info.gname = ""
    return info

tar_bytes = io.BytesIO()
with tarfile.open(fileobj=tar_bytes, mode="w", format=tarfile.USTAR_FORMAT) as tar:
    for name in sorted(entries):
        info = header(name, entries[name])
        if info.isdir():
            tar.addfile(info)
            continue
        with open(os.path.join(tree, name), "rb") as f:
            tar.addfile(info, f)

with open(out, "wb") as f, gzip.GzipFile(filename="", mode="wb", fileobj=f, compresslevel=9, mtime=0) as gz:
    gz.write(tar_bytes.getvalue())
PY
