"""Build/run real attachment bindings with Solar2D's Lua 5.1 (macOS).

Usage: python3 tests/run_attachments.py [--sanitize]
CORONA_NATIVE may point to a different Solar2D Native installation. SPINE_RUNTIME (default 4.2) picks the
runtime line, runtime/spine-<line>, and the line's variant of each test source (name43.cpp for name.cpp).
Build artifacts go to a temporary directory, never into packaged plugins.
"""
from pathlib import Path
import os
import subprocess
import tempfile
import sys

root = Path(__file__).resolve().parents[1]
line = os.environ.get("SPINE_RUNTIME", "4.2")
runtime = root / ("runtime/spine-" + line)


def line_source(name):
    variant = root / "tests" / name.replace(".cpp", line.replace(".", "") + ".cpp")
    return variant if variant.exists() else root / "tests" / name


native = Path(os.environ.get("CORONA_NATIVE", str(Path.home() / "Library/Application Support/Corona/Native")))
sources = sorted((root / "shared").glob("*.cpp"))
sources = [p for p in sources if p.name not in {"Lua_Spine.cpp", "SpineTexture.cpp", "SkeletonDataHolder.cpp", "SpineRenderer.cpp"}]
sources += sorted((runtime / "spine").glob("*.cpp"))
with tempfile.TemporaryDirectory(prefix="spine-attachments-") as build:
    output = Path(build) / "attachment_fixture.so"
    flags = []
    env = os.environ.copy()
    if "--sanitize" in sys.argv:
        # The signed Solar2D Lua executable cannot load ASan under macOS policy.
        # Exercise native ownership in a separate instrumented executable.
        native_test = Path(build) / "attachment_lifetimes"
        subprocess.run(["clang++", "-std=c++17", "-g", "-fsanitize=address,undefined",
                        "-fno-omit-frame-pointer", "-I" + str(root / "shared"), "-I" + str(runtime),
                        str(line_source("attachment_lifetimes.cpp")),
                        *map(str, sorted((runtime / "spine").glob("*.cpp"))),
                        "-o", str(native_test)], check=True)
        subprocess.run([str(native_test)], check=True)
    command = ["clang++", "-std=c++17", "-g", "-bundle", "-undefined", "dynamic_lookup", *flags,
               "-I" + str(root / "shared"), "-I" + str(runtime),
               "-I" + str(native / "Corona/shared/include/Corona"),
               "-I" + str(native / "Corona/shared/include/lua"),
               str(line_source("attachment_fixture.cpp")), *map(str, sources), "-o", str(output)]
    subprocess.run(command, check=True)
    env["LUA_CPATH"] = str(Path(build) / "?.so")
    subprocess.run([str(native / "Corona/mac/bin/lua"), str(root / "tests/attachments.lua")], env=env, check=True)
