#pragma once

#include "CoronaLua.h"
#include "spine/spine.h"

using namespace spine;

void getIKConstraintMt(lua_State* L);

struct LuaIKConstraint
{
    lua_State *L;
    IkConstraint *ikConstraint;

    LuaIKConstraint(lua_State *L, IkConstraint *ikConstraint)
        : L(L), ikConstraint(ikConstraint)
    {
        getIKConstraintMt(L);
        lua_setmetatable(L, -2);
    }

    ~LuaIKConstraint() {
        ikConstraint = nullptr;
        L = nullptr;
    }
};

