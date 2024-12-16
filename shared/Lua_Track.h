#pragma once

#include "CoronaLua.h"
#include "spine/spine.h"

using namespace spine;

void getTrackMt(lua_State* L);

struct LuaTrack
{
    lua_State *L;
    Vector<TrackEntry *> &tracks;
    int trackIndex;

    LuaTrack(lua_State *L, int trackIndex, Vector<TrackEntry *> &tracks) : L(L), trackIndex(trackIndex), tracks(tracks)
    {
        getTrackMt(L);
        lua_setmetatable(L, -2);
    }

    ~LuaTrack()
    {
        L = nullptr;
    }
};

