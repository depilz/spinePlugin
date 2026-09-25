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
        // Keep a registry reference so we can re-push the same userdata later
        lua_pushvalue(L, -1);
        selfRef = luaL_ref(L, LUA_REGISTRYINDEX);
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

