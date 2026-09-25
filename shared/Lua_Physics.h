#pragma once

#include "CoronaLua.h"
#include "spine/spine.h"

using namespace spine;

void getPhysicsMt(lua_State* L);

struct LuaPhysics
{
    lua_State *L;
    Vector<PhysicsConstraint*> constraints;

    LuaPhysics(lua_State *L, Vector<PhysicsConstraint*> constraints) : L(L), constraints(constraints)
    {
        getPhysicsMt(L);
        lua_setmetatable(L, -2);
    }

    ~LuaPhysics()
    {
        constraints.clear();
        L = nullptr;
    }
};

