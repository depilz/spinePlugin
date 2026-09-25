#pragma once

#include "CoronaLua.h"
#include "spine/spine.h"

using namespace spine;

void getTrackMt(lua_State* L);

struct LuaTrack
{
    lua_State *L;
    Vector<TrackEntry *> &tracks;

    LuaTrack(lua_State *L, Vector<TrackEntry *> &tracks) : L(L), tracks(tracks)
    {
        getTrackMt(L);
        lua_setmetatable(L, -2);
    }

    ~LuaTrack()
    {
        L = nullptr;
    }
};

