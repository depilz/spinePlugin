#pragma once

#include "CoronaLua.h"
#include "SkeletonLife.h"
#include "SpineCompat.h"
#include <memory>

using namespace spine;

void getTrackMt(lua_State* L);

struct LuaTrack
{
    lua_State *L;
    Vector<TrackEntry *> &tracks;
    std::shared_ptr<SkeletonLife> alive;

    LuaTrack(lua_State *L, Vector<TrackEntry *> &tracks, std::shared_ptr<SkeletonLife> alive)
        : L(L), tracks(tracks), alive(alive)
    {
        getTrackMt(L);
        lua_setmetatable(L, -2);
    }

    // tracks[i] are track entries, so the proxy reports as one
    void checkAlive(lua_State *state) const
    {
        if (!L || (alive && !*alive))
            luaL_error(state, "Track entry belongs to a removed skeleton");
    }

    ~LuaTrack()
    {
        L = nullptr;
    }
};

