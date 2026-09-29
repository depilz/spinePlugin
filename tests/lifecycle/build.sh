#!/bin/bash
# Lifecycle harness build: the suite's host.c + the repo's real shared/*.cpp (Lua_Spine, SpineTexture,
# SpineRenderer included) + the shared host's spine-cpp runtime and Lua objects. Reads the plugin tree read-only.
#   build.sh asan   -> $OUT/host_asan   (ASan+UBSan)
#   build.sh plain  -> $OUT/host_plain  (no sanitizers, for memory-growth measurements)
#   build.sh mode [-Dflag...] [source...]: another suite's host, compiled with its flags and linked with its sources
#   (tests/animation: -DHOST_NATIVE=<fn> and its helpers, see host.c)
# OUT defaults to $SUITE_OUT, else $SPINE_TEST_OUT/lifecycle. Environment: tests/host/host.sh.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../host/host.sh"
MODE="${1:-asan}"
shift $(( $# > 0 ? 1 : 0 ))
EXTRA_FL=() EXTRA_SRC=()
for a in "$@"; do if [[ "$a" == -* ]]; then EXTRA_FL+=("$a"); else EXTRA_SRC+=("$a"); fi; done
OUT="${OUT:-${SUITE_OUT:-$SPINE_TEST_OUT/lifecycle}}"
FL=$(host_flags "$MODE")
LUAO=$(host_lua "$MODE")
RTO=$(host_runtime "$MODE")
rm -rf "$OUT/obj-$MODE"
host_compile "$MODE" "$OUT/obj-$MODE" "-DHOST_PLUGIN=$HOST_ENTRY" ${EXTRA_FL[@]+"${EXTRA_FL[@]}"} "$W/host.c" \
  "$SPINE_REPO"/shared/*.cpp ${EXTRA_SRC[@]+"${EXTRA_SRC[@]}"}
clang++ $FL "$OUT/obj-$MODE"/*.o "$RTO"/*.o "$LUAO"/*.o -o "$OUT/host_$MODE"
echo "built $OUT/host_$MODE"
