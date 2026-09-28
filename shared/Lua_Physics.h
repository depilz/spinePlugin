#pragma once

#include "CoronaLua.h"
#include "SkeletonLife.h"
#include "SpineCompat.h"
#include <memory>

using namespace spine;

void getPhysicsMt(lua_State* L);

struct LuaPhysics
{
    lua_State *L;
    Vector<PhysicsConstraint*> constraints;
    std::shared_ptr<SkeletonLife> alive;

    LuaPhysics(lua_State *L, Vector<PhysicsConstraint*> constraints, std::shared_ptr<SkeletonLife> alive)
        : L(L), constraints(constraints), alive(alive)
    {
        getPhysicsMt(L);
        lua_setmetatable(L, -2);
    }

    void checkAlive(lua_State *state) const
    {
        if (alive && !*alive)
            luaL_error(state, "Physics constraint belongs to a removed skeleton");
    }

    ~LuaPhysics()
    {
        constraints.clear();
        L = nullptr;
    }
};

