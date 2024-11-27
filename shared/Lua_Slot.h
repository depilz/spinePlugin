#pragma once

#include "CoronaLua.h"
#include "spine/spine.h"

using namespace spine;

void getSlotMt(lua_State* L);

struct LuaSlot
{
    lua_State *L;
    Slot *slot;

    LuaSlot(lua_State *L, Slot *slot) : L(L), slot(slot)
    {
        getSlotMt(L);
        lua_setmetatable(L, -2);
    }

    ~LuaSlot()
    {
        slot = nullptr;
        L = nullptr;
    }
};

