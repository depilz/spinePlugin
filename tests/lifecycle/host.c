/* Lifecycle review host: Solar2D's Lua 5.1.3 + the REAL plugin entry (Lua_Spine.cpp create/loadAtlas/
   loadSkeletonData, SpineTexture.cpp, SkeletonDataHolder.cpp, SpineRenderer.cpp) with a Lua-level Solar2D
   display/graphics/system stub (solar2d_stub.lua).
   Usage: host stub.lua test.lua [args...]
   Build: -DHOST_NATIVE=<fn> adds a suite's native helpers: fn(L) registers them into the __native table on top.
   Env: NO_CLOSE=1 skips lua_close (to compare). */
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include <stdio.h>
#include <stdlib.h>
#include <malloc/malloc.h>
#include <stdarg.h>

lua_State *g_mainL = 0;
int HOST_PLUGIN(lua_State *L); /* -DHOST_PLUGIN=<entry>, host.sh HOST_ENTRY */
#ifdef HOST_NATIVE
int HOST_NATIVE(lua_State *L);
#endif

/* Solar2D API stubs used by the plugin */
lua_State *CoronaLuaGetCoronaThread(lua_State *L) { return g_mainL ? g_mainL : L; }
int CoronaLuaDoCall(lua_State *L, int narg, int nresults) { int s = lua_pcall(L, narg, nresults, 0); if (s && !lua_isnil(L, -1)) { fprintf(stderr, "CoronaLuaDoCall: %s\n", lua_isstring(L, -1) ? lua_tostring(L, -1) : "(error object is not a string)"); lua_pop(L, 1); } return s; }
void CoronaLuaWarning(lua_State *L, const char *fmt, ...) { (void)L; va_list ap; va_start(ap, fmt); fprintf(stderr, "WARNING: "); vfprintf(stderr, fmt, ap); fprintf(stderr, "\n"); va_end(ap); }
int CoronaMemoryCreateInterface(lua_State *L, const void *info) { (void)info; lua_newtable(L); return 1; }

static int heap(lua_State *L) {
    malloc_statistics_t st;
    malloc_zone_statistics(NULL, &st);
    lua_pushnumber(L, (lua_Number)st.size_in_use);
    return 1;
}
static int isMain(lua_State *L) { lua_pushboolean(L, L == g_mainL); return 1; }

int main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "usage: %s stub.lua test.lua\n", argv[0]); return 2; }
    lua_State *L = luaL_newstate();
    g_mainL = L;
    luaL_openlibs(L);
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");
    lua_pushcfunction(L, HOST_PLUGIN);
    lua_setfield(L, -2, "plugin.spine");
    lua_pop(L, 2);
    lua_newtable(L);
    lua_pushcfunction(L, heap); lua_setfield(L, -2, "heap");
    lua_pushcfunction(L, isMain); lua_setfield(L, -2, "isMain");
#ifdef HOST_NATIVE
    HOST_NATIVE(L);
#endif
    lua_setglobal(L, "__native");
    lua_newtable(L);
    for (int i = 0; i < argc; ++i) { lua_pushstring(L, argv[i]); lua_rawseti(L, -2, i - 2); }
    lua_setglobal(L, "arg");
    if (luaL_dofile(L, argv[1])) { fprintf(stderr, "STUB ERROR: %s\n", lua_tostring(L, -1)); return 1; }
    int rc = luaL_dofile(L, argv[2]);
    if (rc) { fprintf(stderr, "LUA ERROR: %s\n", lua_tostring(L, -1)); }
    if (getenv("NO_CLOSE")) { fprintf(stderr, "[host] skipping lua_close\n"); return rc ? 1 : 0; }
    fprintf(stderr, "[host] lua_close begin\n");
    lua_close(L);
    fprintf(stderr, "[host] lua_close done\n");
    return rc ? 1 : 0;
}
