/* Lua 5.1.3 host that preloads the modules listed in HOST_PRELOAD, e.g.
   -DHOST_PRELOAD='X(realdata_fixture) X(attachment_fixture)' makes require("realdata_fixture")
   call luaopen_realdata_fixture. Usage: host script.lua [args...] */
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include <stdio.h>

#ifndef HOST_PRELOAD
#define HOST_PRELOAD
#endif

#define X(m) int luaopen_##m(lua_State *L);
HOST_PRELOAD
#undef X

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s script.lua\n", argv[0]); return 2; }
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");
#define X(m) lua_pushcfunction(L, luaopen_##m); lua_setfield(L, -2, #m);
    HOST_PRELOAD
#undef X
    lua_pop(L, 2);
    lua_newtable(L);
    for (int i = 0; i < argc; ++i) { lua_pushstring(L, argv[i]); lua_rawseti(L, -2, i - 1); }
    lua_setglobal(L, "arg");
    int rc = luaL_dofile(L, argv[1]);
    if (rc) { fprintf(stderr, "LUA ERROR: %s\n", lua_tostring(L, -1)); lua_close(L); return 1; }
    lua_close(L); /* full GC of everything: exercises __gc ordering at shutdown */
    return 0;
}
