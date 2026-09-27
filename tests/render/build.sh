#!/bin/bash
# Render harness build: the shared host.c preloading the plugin entry (as plugin_spine) and renderfx + renderfx.cpp
# + the repo's real shared/*.cpp (Lua_Spine, SpineTexture, SpineRenderer included) + the shared host's spine-cpp
# runtime and Lua objects; bench from bench.cpp + the runtime. Reads the plugin tree read-only.
#   build.sh asan   -> $OUT/host_asan, $OUT/bench_asan    (ASan+UBSan)
#   build.sh plain  -> $OUT/host_plain, $OUT/bench_plain  (no sanitizers, for timings)
# OUT defaults to $SUITE_OUT, else $SPINE_TEST_OUT/render. Environment: tests/host/host.sh.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../host/host.sh"
MODE="${1:-asan}"
OUT="${OUT:-${SUITE_OUT:-$SPINE_TEST_OUT/render}}"
FL=$(host_flags "$MODE")
LUAO=$(host_lua "$MODE")
RTO=$(host_runtime "$MODE")
rm -rf "$OUT/obj-$MODE" "$OUT/bench-$MODE"
host_compile "$MODE" "$OUT/obj-$MODE" "-DHOST_PLUGIN=$HOST_ENTRY" "-DHOST_PRELOAD=X(renderfx)" \
  "$HOST_DIR/host.c" "$W/renderfx.cpp" "$SPINE_REPO"/shared/*.cpp
clang++ $FL "$OUT/obj-$MODE"/*.o "$RTO"/*.o "$LUAO"/*.o -o "$OUT/host_$MODE"
host_compile "$MODE" "$OUT/bench-$MODE" "$W/bench.cpp"
clang++ $FL "$OUT/bench-$MODE"/*.o "$RTO"/*.o -o "$OUT/bench_$MODE"
echo "built $OUT/host_$MODE $OUT/bench_$MODE"
