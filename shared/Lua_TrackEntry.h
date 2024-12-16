#pragma once

#include "CoronaLua.h"
#include "spine/spine.h"

using namespace spine;

void getEntryMt(lua_State* L);

struct LuaTrackEntry
{
    lua_State *L;
    TrackEntry *entry;

    LuaTrackEntry(lua_State *L, TrackEntry *entry) : L(L), entry(entry)
    {
        getEntryMt(L);
        lua_setmetatable(L, -2);
    }

    ~LuaTrackEntry()
    {
        entry = nullptr;
        L = nullptr;
    }
};

