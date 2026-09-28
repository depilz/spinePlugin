#pragma once

#include "CoronaLua.h"
#include "SkeletonLife.h"
#include "SpineCompat.h"
#include <memory>

using namespace spine;

void getFillMt(lua_State *L);

// Forward declaration to avoid circular dependency
struct SpineSkeleton;

struct LuaFill
{
    SpineSkeleton *owner = nullptr; // provides access to skeleton and effectData
    std::shared_ptr<SkeletonLife> alive;    // owner is valid only while *alive

    LuaFill(lua_State *L, SpineSkeleton *owner, std::shared_ptr<SkeletonLife> alive) : owner(owner), alive(alive)
    {
        getFillMt(L);
        lua_setmetatable(L, -2);
    }

    void checkAlive(lua_State *state) const
    {
        if (!owner || !alive || !*alive)
            luaL_error(state, "Fill belongs to a removed skeleton");
    }
};

