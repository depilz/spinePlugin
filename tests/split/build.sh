#!/bin/bash
# Split harness build: the shared host.c preloading plugin_spine and splitfx + splitfx.cpp + ref_renderer.cpp
# (the checkout's SkeletonRenderer.cpp recompiled as an unbatched reference) + the repo's real shared/*.cpp + the
# shared host's spine-cpp runtime and Lua objects. Reads the plugin tree read-only.
#   build.sh asan   -> $OUT/host_asan    (ASan+UBSan; operator new counted for the render-11 check)
#   build.sh plain  -> $OUT/host_plain   (no sanitizers, for timings)
# OUT defaults to $SUITE_OUT, else $SPINE_TEST_OUT/split. Environment: tests/host/host.sh.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../host/host.sh"
MODE="${1:-asan}"
OUT="${OUT:-${SUITE_OUT:-$SPINE_TEST_OUT/split}}"
FL=$(host_flags "$MODE")
LUAO=$(host_lua "$MODE")
RTO=$(host_runtime "$MODE")
rm -rf "$OUT/obj-$MODE" "$OUT/gen-$MODE"
mkdir -p "$OUT/gen-$MODE"
sed 's/^static RenderCommand \*batchCommands(/static RenderCommand *batchCommands_orig(/' \
  "$SPINE_REPO/shared/spine/SkeletonRenderer.cpp" >"$OUT/gen-$MODE/ref_body.inc"
host_compile "$MODE" "$OUT/obj-$MODE" "-DHOST_PRELOAD=X(plugin_spine) X(splitfx)" -I"$OUT/gen-$MODE" \
  "$HOST_DIR/host.c" "$W/splitfx.cpp" "$W/ref_renderer.cpp" "$SPINE_REPO"/shared/*.cpp
clang++ $FL "$OUT/obj-$MODE"/*.o "$RTO"/*.o "$LUAO"/*.o -o "$OUT/host_$MODE"
echo "built $OUT/host_$MODE"
