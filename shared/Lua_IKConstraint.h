#pragma once

#include "CoronaLua.h"
#include "SkeletonLife.h"
#include "SpineCompat.h"
#include <memory>

using namespace spine;

void getIKConstraintMt(lua_State* L);

struct LuaIKConstraint
{
    lua_State *L;
    IkConstraint *ikConstraint;
    Skeleton *skeleton; // the owner, for updateCache() after a target change
    std::shared_ptr<SkeletonLife> alive;

    LuaIKConstraint(lua_State *L, IkConstraint *ikConstraint, Skeleton *skeleton, std::shared_ptr<SkeletonLife> alive)
        : L(L), ikConstraint(ikConstraint), skeleton(skeleton), alive(alive)
    {
        getIKConstraintMt(L);
        lua_setmetatable(L, -2);
    }

    void checkAlive(lua_State *state) const
    {
        if (!ikConstraint || (alive && !*alive))
            luaL_error(state, "IK constraint belongs to a removed skeleton");
    }

    ~LuaIKConstraint() {
        ikConstraint = nullptr;
        L = nullptr;
    }
};

