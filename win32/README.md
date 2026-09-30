# win32

`Plugin.sln` builds `plugin_spine42.dll` (`Plugin.vcxproj`) and `plugin_spine43.dll` (`Plugin43.vcxproj`)
with the `v143` toolset. `CORONA_ROOT` must point at the Solar2D Native SDK.

```
MSBuild win32\Plugin.sln /p:Configuration=Release /p:Platform=Win32
```

## Release build options

The Release|Win32 configuration of both projects adds options that keep build-machine paths out of the DLL and
make it reproducible with MSVC 14.44 (toolset `v143`):

- `cl`: `"/pathmap:<repo root>\="` rewrites the repo root to nothing, so `__FILE__` reads `shared\…` /
  `runtime\…` even with `/FC`. The root comes from `NormalizeDirectory`, so it ends in `\` before `=`, and the
  quotes keep a root with spaces in one argument. `/pathmap` needs `/experimental:deterministic`; without it
  14.44 ignores the map with warning D9007.
- `cl` and `link`: `/Brepro`. The PE TimeDateStamp becomes a content hash and the DLL gains a REPRO debug entry,
  so two builds of the same commit from different directories give the same bytes.
- `link`: `/PDBALTPATH:%_PDB%`. The DLL records only the PDB file name (`plugin_spine42.pdb`,
  `plugin_spine43.pdb`), not its path.

The projects' Debug configuration keeps full paths for local debugging; `Plugin.sln` maps both of its
configurations to project Release, so a solution build always gets these options. `/DEBUG` stays on: the PDB is
written next to the DLL, holds absolute paths and is kept out of release archives.

## CopyToSimulator

By default a build only writes to its output directory. Pass `/p:CopyToSimulator=true` to also copy the
built DLL into `%APPDATA%\Corona Labs\Corona Simulator\Plugins`, the live Corona Simulator plugins folder:

```
MSBuild win32\Plugin.sln /p:Configuration=Release /p:Platform=Win32 /p:CopyToSimulator=true
```
