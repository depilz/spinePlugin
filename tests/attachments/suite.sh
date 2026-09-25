#!/bin/bash
# attachments: tests/run_attachments.py, then tests/attachments.lua in the shared ASan host, where the
# bindings themselves are instrumented.
set -euo pipefail
TESTS="$(cd "$(dirname "$0")/.." && pwd)"
source "$TESTS/lib.sh"
source "$TESTS/host/host.sh"

# native_shim: a Corona Native layout for run_attachments.py; its lua is the host without preloaded modules
native_shim() {
  local shim="$SUITE_OUT/native" lua
  lua=$(host_lua asan) || return 1
  mkdir -p "$shim/Corona/shared/include" "$shim/Corona/mac/bin"
  ln -sfn "$CORONA_NATIVE/Corona/shared/include/Corona" "$shim/Corona/shared/include/Corona"
  ln -sfn "$LUA51_SRC" "$shim/Corona/shared/include/lua"
  host_compile asan "$SUITE_OUT/lua.obj" "$HOST_DIR/host.c" || return 1
  clang $(host_flags asan) "$SUITE_OUT/lua.obj/host.o" "$lua"/*.o -o "$shim/Corona/mac/bin/lua" || return 1
  echo "$shim"
}

[[ "$(cd "$SPINE_REPO" && pwd -P)" == "$(cd "$TESTS/.." && pwd -P)" ]] ||
  { echo "attachments: run_attachments.py only builds its own checkout; SPINE_REPO=$SPINE_REPO is not $TESTS/.." >&2; exit 1; }
shim=$(native_shim) || exit 1
run_test run_attachments.py env CORONA_NATIVE="$shim" python3 "$TESTS/run_attachments.py" --sanitize
host=$("$TESTS/host/build.sh" asan)
run_test attachments.lua "$host" "$TESTS/attachments.lua"
