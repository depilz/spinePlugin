# win32

`Plugin.sln` builds `plugin_spine42.dll` (`Plugin.vcxproj`) and `plugin_spine43.dll` (`Plugin43.vcxproj`)
with the `v143` toolset. `CORONA_ROOT` must point at the Solar2D Native SDK.

```
MSBuild win32\Plugin.sln /p:Configuration=Release /p:Platform=Win32
```

## CopyToSimulator

By default a build only writes to its output directory. Pass `/p:CopyToSimulator=true` to also copy the
built DLL into `%APPDATA%\Corona Labs\Corona Simulator\Plugins`, the live Corona Simulator plugins folder:

```
MSBuild win32\Plugin.sln /p:Configuration=Release /p:Platform=Win32 /p:CopyToSimulator=true
```
