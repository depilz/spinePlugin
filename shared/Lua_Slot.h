#pragma once

#include "CoronaLua.h"
#include "spine/spine.h"
#include "DataHolder.h"

using namespace spine;

void getSlotMt(lua_State* L);

struct LuaSlot
{
    lua_State *L;
    Slot *slot;

    std::shared_ptr<DataHolder<SkeletonData>> dataOwner;
    std::shared_ptr<bool> alive;

    LuaSlot(lua_State *L, Slot *slot,
            std::shared_ptr<DataHolder<SkeletonData>> dataOwner = nullptr,
            std::shared_ptr<bool> alive = nullptr)
        : L(L), slot(slot), dataOwner(dataOwner), alive(alive)
    {
        getSlotMt(L);
        lua_setmetatable(L, -2);
    }

    void checkAlive(lua_State *state) const
    {
        if (!slot || (alive && !*alive))
            luaL_error(state, "Slot belongs to a removed skeleton");
    }

    ~LuaSlot()
    {
        slot = nullptr;
        L = nullptr;
    }
};

