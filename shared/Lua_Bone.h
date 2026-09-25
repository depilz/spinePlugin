#pragma once

#include "CoronaLua.h"
#include "spine/spine.h"

using namespace spine;

void getBoneMt(lua_State* L);

struct LuaBone
{
    lua_State *L;
    Bone *bone;

    LuaBone(lua_State *L, Bone *bone)
        : L(L), bone(bone)
    {
        getBoneMt(L);
        lua_setmetatable(L, -2);
    }

    ~LuaBone()
    {
        bone = nullptr;
        L = nullptr;
    }
};

