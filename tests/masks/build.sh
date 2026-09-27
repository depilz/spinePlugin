#!/bin/bash
# Masks comparator build: comparator.cpp + the 4.2 reference clipper gdxclip.cpp (without fused multiply-add, as Java)
# + the shared host's spine-cpp runtime objects of the line (runtime/spine-$SPINE_RUNTIME/spine). Reads the plugin
# tree read-only.
#   build.sh asan   -> $OUT/comparator_asan    (ASan+UBSan)
#   build.sh plain  -> $OUT/comparator_plain   (no sanitizers)
# OUT defaults to $SUITE_OUT, else $SPINE_TEST_OUT/masks. Environment: tests/host/host.sh.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../host/host.sh"
MODE="${1:-asan}"
OUT="${OUT:-${SUITE_OUT:-$SPINE_TEST_OUT/masks}}"
OBJ="$OUT/comparator-$MODE"
rm -rf "$OBJ"
host_compile "$MODE" "$OBJ" "$W/comparator.cpp"
host_compile "$MODE" "$OBJ" -ffp-contract=off "$W/gdxclip.cpp"
clang++ $(host_flags "$MODE") "$OBJ"/*.o "$(host_runtime "$MODE")"/*.o -o "$OUT/comparator_$MODE"
echo "built $OUT/comparator_$MODE"
