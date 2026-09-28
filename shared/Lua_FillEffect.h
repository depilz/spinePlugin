#pragma once

#include "CoronaLua.h"
#include "SkeletonLife.h"
#include <memory>

// Forward decls
struct SpineSkeleton;
class Lua_EffectData;

// Pushes/defines the metatable for the effect userdata
void getFillEffectMt(lua_State *L);

// Lua userdata that provides table-like access to the skeleton's effectData.
// This does not own effectData; it just forwards reads/writes to
// SpineSkeleton::effectData (created lazily on writes or on first read by caller).
struct LuaFillEffect {
    lua_State *L;
    SpineSkeleton *owner; // access to effectData and skeleton
    std::shared_ptr<SkeletonLife> alive; // owner is valid only while *alive

    LuaFillEffect(lua_State *L, SpineSkeleton *owner, std::shared_ptr<SkeletonLife> alive) : L(L), owner(owner), alive(alive) {
        getFillEffectMt(L);
        lua_setmetatable(L, -2);
    }

    void checkAlive(lua_State *state) const {
        if (!owner || !alive || !*alive)
            luaL_error(state, "Effect belongs to a removed skeleton");
    }
};
