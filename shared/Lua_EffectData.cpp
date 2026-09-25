#include "Lua_EffectData.h"
#include <cassert>

// Note: readNumberArray and writeNumberArray are currently unused but kept for future use
#if 0
static std::vector<float> readNumberArray(lua_State *L, int index) {
    std::vector<float> out;
    // Absolute index
    if (index < 0) index = lua_gettop(L) + index + 1;

    // Iterate numeric sequence 1..n
    lua_Integer n = lua_objlen(L, index);
    out.reserve((size_t)n);
    for (lua_Integer i = 1; i <= n; ++i) {
        lua_rawgeti(L, index, static_cast<int>(i));
        if (!lua_isnumber(L, -1)) {
            luaL_error(L, "Effect attribute array must contain only numbers (index %d)", (int)i);
            // luaL_error longjmps; but keep stack balanced in theory
        }
        out.emplace_back((float)lua_tonumber(L, -1));
        lua_pop(L, 1);
    }
    return out;
}

static void writeNumberArray(lua_State *L, const std::vector<float> &arr) {
    lua_createtable(L, (int)arr.size(), 0);
    for (size_t i = 0; i < arr.size(); ++i) {
        lua_pushnumber(L, arr[i]);
        lua_rawseti(L, -2, (int)i + 1);
    }
}
#endif
