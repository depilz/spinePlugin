#pragma once

#include "CoronaLua.h"

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

    LuaFillEffect(lua_State *L, SpineSkeleton *owner) : L(L), owner(owner) {
        getFillEffectMt(L);
        lua_setmetatable(L, -2);
    }
};
