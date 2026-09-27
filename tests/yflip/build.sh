#!/bin/bash
# Y-flip build: the matrix bench (yflip.cpp + the shared host's spine-cpp runtime) and the Lua host (the shared host.c
# preloading realdata_fixture, built from yflip_fixture.cpp + the shared host's bindings, runtime and Lua objects).
# Both take the plugin's coordinate configuration from the checkout as compiled for the line (shared/*.cpp
# preprocessed against it, so SPINE_43() is resolved): skeleton scaleY -1 while they call setScaleY(-1), Bone::yDown
# true while they call setYDown(true), else the runtime's Bone::yDown default. Reads the plugin tree read-only.
#   build.sh asan   -> $OUT/host_asan, $OUT/bench_asan    (ASan+UBSan)
#   build.sh plain  -> $OUT/host_plain, $OUT/bench_plain  (no sanitizers)
# OUT defaults to $SUITE_OUT, else $SPINE_TEST_OUT/yflip. Environment: tests/host/host.sh.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../host/host.sh"
MODE="${1:-asan}"
OUT="${OUT:-${SUITE_OUT:-$SPINE_TEST_OUT/yflip}}"
mkdir -p "$OUT"
PLUGIN_I="$OUT/plugin-$MODE.i"
for f in "$SPINE_REPO"/shared/*.cpp; do clang++ -std=c++17 -E -P "${HOST_INC[@]}" "$f"; done >"$PLUGIN_I"
SCALE_Y=1; Y_DOWN=$(sed -nE 's/^bool Bone::yDown = (true|false);$/\1/p' "$HOST_RUNTIME/spine/Bone.cpp")
[[ -n "$Y_DOWN" ]] || { echo "yflip: no Bone::yDown default in $HOST_RUNTIME/spine/Bone.cpp" >&2; exit 1; }
if grep -q 'setScaleY(-1)' "$PLUGIN_I"; then SCALE_Y=-1; fi
if grep -q 'setYDown(true)' "$PLUGIN_I"; then Y_DOWN=true; fi
CONFIG="$OUT/plugin_config-$MODE.cpp"
printf 'extern const float kPluginScaleY = %s;\nextern const bool kPluginYDown = %s;\n' "$SCALE_Y" "$Y_DOWN" >"$CONFIG"
echo "plugin configuration: scaleY=$SCALE_Y yDown=$Y_DOWN"
host_build "$MODE" "$OUT/host_$MODE" realdata_fixture "$W/yflip_fixture.cpp" "$CONFIG"
rm -rf "$OUT/bench-$MODE"
host_compile "$MODE" "$OUT/bench-$MODE" "$W/yflip.cpp" "$CONFIG"
clang++ $(host_flags "$MODE") "$OUT/bench-$MODE"/*.o "$(host_runtime "$MODE")"/*.o -o "$OUT/bench_$MODE"
echo "built $OUT/host_$MODE $OUT/bench_$MODE"
