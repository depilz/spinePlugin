#pragma once

#include "CoronaLua.h"
#include "spine/spine.h"

using namespace spine;

void getSkinMt(lua_State* L);

struct LuaSkin
{
    lua_State* L;
    Skin* skin;

    LuaSkin(lua_State* L, Skin* skin)
        : L(L), skin(skin)
    {
        getSkinMt(L);
        lua_setmetatable(L, -2);
    }

    ~LuaSkin()
    {
        skin = nullptr;
        L = nullptr;
    }
};
