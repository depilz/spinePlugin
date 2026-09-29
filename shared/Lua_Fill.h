#pragma once

#include "CoronaLua.h"
#include "spine/spine.h"

using namespace spine;

void getFillMt(lua_State *L);

// Forward declaration to avoid circular dependency
struct SpineSkeleton;

struct LuaFill
{
    lua_State *L;
    SpineSkeleton *owner = nullptr; // provides access to skeleton and effectData
    int selfRef = LUA_NOREF;        // registry reference to this userdata

    LuaFill(lua_State *L, SpineSkeleton *owner) : L(L), owner(owner)
    {
        getFillMt(L);
        lua_setmetatable(L, -2);
        // 1.2.6: no registry self-reference any more; it made every obj.fill access immortal (never collected)
    }

    ~LuaFill()
    {
        if (L && selfRef != LUA_NOREF)
        {
            luaL_unref(L, LUA_REGISTRYINDEX, selfRef);
            selfRef = LUA_NOREF;
        }
        L = nullptr;
        owner = nullptr;
    }
};

