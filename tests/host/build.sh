#!/bin/bash
# Builds the shared host $SPINE_TEST_OUT/host/<mode>_lua (mode asan|plain, default asan) with
# realdata_fixture and attachment_fixture preloaded, and prints its path. Environment: host.sh.
set -euo pipefail
source "$(dirname "$0")/host.sh"
MODE="${1:-asan}"
GEN="$SPINE_TEST_OUT/host/gen"
mkdir -p "$GEN"
# attachment_fixture.cpp defines the same Corona stubs as realdata_fixture.cpp; link a copy without them.
sed -e 's/^void engine_removeMesh.*$//' -e 's/^void renderCommands.*$//' \
    -e 's/^extern "C" lua_State \*CoronaLuaGetCoronaThread.*$//' \
    -e 's/^SpineExtension \*spine::getDefaultExtension.*$//' \
    "$SPINE_REPO/tests/attachment_fixture.cpp" > "$GEN/attachment_fixture_nostubs.cpp"
BIN="$SPINE_TEST_OUT/host/${MODE}_lua"
host_build "$MODE" "$BIN" "realdata_fixture attachment_fixture" \
  "$HOST_DIR/realdata_fixture.cpp" "$GEN/attachment_fixture_nostubs.cpp"
echo "$BIN"
