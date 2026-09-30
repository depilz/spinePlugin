# tools/release

Builds and packs the `data.tgz` archives under `plugin/com.studycat/plugin.spine<NN>/` so that no binary and no tar
header carries a build-machine path or user name, and the same inputs give the same bytes. Each script's header
(`--help`) is its full contract.

## pack.sh

```
tools/release/pack.sh --mtime EPOCH TREE OUT.tgz [MEMBER...]
```

Packs TREE (or its MEMBERs) into a plain ustar archive: entries sorted, every mtime EPOCH, uid/gid 0, empty user and
group names, no pax records, no `._*` members, gzip MTIME 0 without a file name. Modes depend only on path and type.
OUT must lie outside the packed members: an OUT equal to or under one (a stale OUT inside a TREE packed without
MEMBERs included) exits 2 with nothing written. `android/build.sh` packs through it with the epoch of the last commit
outside `plugin/`, naming its members, so its OUT beside them in the build dir packs.

## build.sh

```
<clone>/tools/release/build.sh <line> --commit REV --out DIR [--symbols DIR] \
    [--dll FILE --dll-sha256 HEX --dll-log FILE] [platform...]
```

Runs from a clean git clone whose `HEAD^{tree}` equals `REV^{tree}`, with DIR and the symbols dir outside the clone.
It builds android (`android/build.sh`), iphone (`xcodebuild`, Release, `ZERO_AR_DATE=1`), mac-sim (the sim suite's
`build_dylib`, never touching the user's Simulator plugins dir) and linux-sim (the Lua stub), takes the win32 DLL
built in the Windows VM as an input checked against its sha256, and packs all six with `pack.sh` into
`DIR/plugin.spine<NN>/`. `DIR/pack.log` records the commit, tree, epoch, toolchains and every sha256.
mac-sim reads `build_dylib`'s output contract, stated where it is defined in `tests/sim/suite.sh`: the dylib's
directory keeps `build.log` and `dd/Build/Products/Release/<product>.dylib` with its `.dSYM`.
`tools/release-gate/gate.sh --line <line> --plugin-dir DIR/plugin.spine<NN>` must then print 18 OK lines.

## Pinned toolchains

- Xcode 26.4 (`DEVELOPER_DIR`), with `CORONA_ROOT` set to `$CORONA/Native`
- Android NDK 30.0.16248370 (`ANDROID_NDK`), with `CORONA=/Applications/Corona-3731` exported
- MSVC v143 14.44.35207, Release|Win32, in the VM (see `win32/README.md`)

Each can be overridden by its environment variable; `pack.log` records the ones used.

## Symbols

Debug symbols never go into an archive. The iOS `.a` keeps its DWARF, with repo and Corona paths mapped by the
Release build settings. The mac dylib is `strip -S`'d and re-signed ad hoc; its dSYM goes to `<symbols>/mac-sim/`.
The win32 DLL records only its PDB file name, and the PDB is kept next to the VM build output. Android libraries
are stripped by the NDK.
