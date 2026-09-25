# Shared Lua host build; source this file from bash. Object sets are compiled once per
# SPINE_TEST_OUT, keyed by mode and source content, and reused by every suite.
#   SPINE_TEST_OUT  required: build products go under $SPINE_TEST_OUT/host
#   SPINE_REPO      checkout whose shared/ is built (default: the one containing this file)
#   LUA51_SRC       Lua 5.1.3 src dir (default: tests/third_party/lua-5.1.3/src)
#   CORONA_NATIVE   Corona Native root holding Corona/shared/include/Corona (default: tests/third_party/solar2d)
#   SDKROOT         taken as is; linking needs the Xcode 26.4 SDK
# Modes: asan (-fsanitize=address,undefined) or plain.

HOST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPINE_REPO="${SPINE_REPO:-$(cd "$HOST_DIR/../.." && pwd)}"
LUA51_SRC="${LUA51_SRC:-$(cd "$HOST_DIR/../third_party/lua-5.1.3/src" && pwd)}"
CORONA_NATIVE="${CORONA_NATIVE:-$(cd "$HOST_DIR/../third_party/solar2d" && pwd)}"
: "${SPINE_TEST_OUT:?SPINE_TEST_OUT must name the build output directory}"
HOST_INC=(-I"$LUA51_SRC" -I"$SPINE_REPO/shared" -I"$SPINE_REPO/shared/spine" -I"$CORONA_NATIVE/Corona/shared/include/Corona")
HOST_JOBS=$(sysctl -n hw.ncpu)

# host_flags mode: compile and link flags of the mode
host_flags() {
  case "$1" in
    asan) echo -g -O1 -fno-omit-frame-pointer -fsanitize=address,undefined ;;
    plain) echo -g -O1 ;;
    *) echo "host: unknown mode '$1' (asan|plain)" >&2; return 1 ;;
  esac
}

# host_compile mode dir [-flags...] sources...: one object per source into dir
host_compile() {
  local mode=$1 dir=$2 fl f p rc=0 extra=() pids=() cc=(); shift 2
  fl=$(host_flags "$mode") || return 1
  while [[ "${1:-}" == -* ]]; do extra+=("$1"); shift; done
  mkdir -p "$dir"
  for f in "$@"; do
    if [[ "$f" == *.c ]]; then cc=(clang); else cc=(clang++ -std=c++17); fi
    "${cc[@]}" -c $fl ${extra[@]+"${extra[@]}"} "${HOST_INC[@]}" "$f" -o "$dir/$(basename "${f%.*}").o" &
    pids+=($!)
    if (( ${#pids[@]} >= HOST_JOBS )); then wait "${pids[0]}" || rc=1; pids=("${pids[@]:1}"); fi
  done
  for p in ${pids[@]+"${pids[@]}"}; do wait "$p" || rc=1; done
  return $rc
}

_host_key() { cat "$@" | shasum | cut -c1-12; }

# _host_objs mode name key [-flags...] sources...: prints the object dir, compiling it on first use
_host_objs() {
  local mode=$1 name=$2 key=$3; shift 3
  local dir="$SPINE_TEST_OUT/host/$mode/$name-$key"
  if [[ ! -d "$dir" ]]; then
    rm -rf "$dir.tmp"
    host_compile "$mode" "$dir.tmp" "$@" >&2 || { rm -rf "$dir.tmp"; return 1; }
    mv "$dir.tmp" "$dir"
  fi
  echo "$dir"
}

_host_shared_key() {
  _host_key "$SPINE_REPO"/shared/*.* "$SPINE_REPO"/shared/spine/* "$CORONA_NATIVE"/Corona/shared/include/Corona/*.h
}

# host_lua mode: Lua 5.1.3 library objects
host_lua() {
  local f srcs=()
  for f in "$LUA51_SRC"/*.c; do
    case "${f##*/}" in lua.c|luac.c|print.c|noparser.c) ;; *) srcs+=("$f") ;; esac
  done
  _host_objs "$1" lua "$(_host_key "$LUA51_SRC"/*.[ch])" -DLUA_USE_MACOSX "${srcs[@]}"
}

# host_runtime mode: spine-cpp runtime objects (shared/spine)
host_runtime() {
  _host_objs "$1" runtime "$(_host_shared_key)" "$SPINE_REPO"/shared/spine/*.cpp
}

# host_bindings mode: plugin binding objects, shared/*.cpp minus the files that need the Corona runtime
host_bindings() {
  local f srcs=()
  for f in "$SPINE_REPO"/shared/*.cpp; do
    case "${f##*/}" in Lua_Spine.cpp|SpineTexture.cpp|SkeletonDataHolder.cpp|SpineRenderer.cpp) ;; *) srcs+=("$f") ;; esac
  done
  _host_objs "$1" bindings "$(_host_shared_key)" "${srcs[@]}"
}

# host_build mode binary "module..." sources...: links host.c preloading the modules, the sources,
# the bindings, the runtime and Lua. The sources must provide the Corona stubs the bindings call.
host_build() {
  local mode=$1 bin=$2 m pre="" fl lua rt bind
  for m in $3; do pre+="X($m) "; done
  shift 3
  fl=$(host_flags "$mode") && lua=$(host_lua "$mode") && rt=$(host_runtime "$mode") && bind=$(host_bindings "$mode") || return 1
  rm -rf "$bin.obj"
  host_compile "$mode" "$bin.obj" "-DHOST_PRELOAD=$pre" "$HOST_DIR/host.c" "$@" || return 1
  clang++ $fl "$bin.obj"/*.o "$bind"/*.o "$rt"/*.o "$lua"/*.o -o "$bin"
}
