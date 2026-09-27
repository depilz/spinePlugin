#!/bin/bash
# Split-oracle harness build shared by the split and probe-batching suites (their build.sh call it): the shared host.c
# preloading the plugin entry (as plugin_spine) and splitfx + splitfx.cpp + ref_renderer.cpp (the checkout's
# SkeletonRenderer.cpp recompiled as an unbatched reference) + the repo's real shared/*.cpp + the shared host's
# spine-cpp runtime and Lua objects. Reads the plugin tree read-only.
#   build.sh suite asan   -> $OUT/host_asan    (ASan+UBSan; operator new counted unless NO_COUNTED_NEW=1)
#   build.sh suite plain  -> $OUT/host_plain   (no sanitizers, for timings)
# OUT defaults to $SUITE_OUT, else $SPINE_TEST_OUT/<suite>. Environment: tests/host/host.sh.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../host/host.sh"
SUITE="$1"
MODE="${2:-asan}"
OUT="${OUT:-${SUITE_OUT:-$SPINE_TEST_OUT/$SUITE}}"
FL=$(host_flags "$MODE")
LUAO=$(host_lua "$MODE")
RTO=$(host_runtime "$MODE")
DEFS=()
[[ "$MODE" == asan && "${NO_COUNTED_NEW:-}" == 1 ]] && DEFS=(-DNO_COUNTED_NEW)
rm -rf "$OUT/obj-$MODE" "$OUT/gen-$MODE"
mkdir -p "$OUT/gen-$MODE"
sed 's/^static RenderCommand \*batchCommands(/static RenderCommand *batchCommands_orig(/' \
  "$HOST_RUNTIME/spine/SkeletonRenderer.cpp" >"$OUT/gen-$MODE/ref_body.inc"
host_compile "$MODE" "$OUT/obj-$MODE" "-DHOST_PLUGIN=$HOST_ENTRY" "-DHOST_PRELOAD=X(splitfx)" ${DEFS[@]+"${DEFS[@]}"} -I"$OUT/gen-$MODE" \
  "$HOST_DIR/host.c" "$W/splitfx.cpp" "$W/ref_renderer.cpp" "$SPINE_REPO"/shared/*.cpp
clang++ $FL "$OUT/obj-$MODE"/*.o "$RTO"/*.o "$LUAO"/*.o -o "$OUT/host_$MODE"
echo "built $OUT/host_$MODE"
