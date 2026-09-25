#!/bin/bash
# Y-flip build: the matrix bench (yflip.cpp + the shared host's spine-cpp runtime) and the Lua host (the shared host.c
# preloading realdata_fixture, built from yflip_fixture.cpp + the shared host's bindings, runtime and Lua objects).
# Both take the plugin's coordinate configuration from the checkout: skeleton scaleY -1 while shared/Lua_Spine.cpp
# calls setScaleY(-1), Bone::yDown while any shared/*.cpp calls setYDown(true). Reads the plugin tree read-only.
#   build.sh asan   -> $OUT/host_asan, $OUT/bench_asan    (ASan+UBSan)
#   build.sh plain  -> $OUT/host_plain, $OUT/bench_plain  (no sanitizers)
# OUT defaults to $SUITE_OUT, else $SPINE_TEST_OUT/yflip. Environment: tests/host/host.sh.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../host/host.sh"
MODE="${1:-asan}"
OUT="${OUT:-${SUITE_OUT:-$SPINE_TEST_OUT/yflip}}"
SCALE_Y=1; Y_DOWN=false
grep -q 'setScaleY(-1)' "$SPINE_REPO/shared/Lua_Spine.cpp" && SCALE_Y=-1
grep -q 'setYDown(true)' "$SPINE_REPO"/shared/*.cpp && Y_DOWN=true
CONFIG="$OUT/plugin_config-$MODE.cpp"
mkdir -p "$OUT"
printf 'extern const float kPluginScaleY = %s;\nextern const bool kPluginYDown = %s;\n' "$SCALE_Y" "$Y_DOWN" >"$CONFIG"
echo "plugin configuration: scaleY=$SCALE_Y yDown=$Y_DOWN"
host_build "$MODE" "$OUT/host_$MODE" realdata_fixture "$W/yflip_fixture.cpp" "$CONFIG"
rm -rf "$OUT/bench-$MODE"
host_compile "$MODE" "$OUT/bench-$MODE" "$W/yflip.cpp" "$CONFIG"
clang++ $(host_flags "$MODE") "$OUT/bench-$MODE"/*.o "$(host_runtime "$MODE")"/*.o -o "$OUT/bench_$MODE"
echo "built $OUT/host_$MODE $OUT/bench_$MODE"
