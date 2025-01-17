#include "Lua_Track.h"
#include "Lua_TrackEntry.h"

static int track_index(lua_State *L)
{
    LuaTrack *trackUserdata = (LuaTrack *)luaL_checkudata(L, 1, "SpineTrack");

    if (!trackUserdata->L)
    {
        return 0;
    }

    if (!lua_isnumber(L, 2))
    {
        return 0;
    }
    int index = luaL_checkint(L, 2) - 1;

    if (index >= 0 && index < trackUserdata->tracks.size())
    {
        TrackEntry *track = trackUserdata->tracks[index];
        if (track)
        {
            LuaTrackEntry *entryUserdata = (LuaTrackEntry *)lua_newuserdata(L, sizeof(LuaTrackEntry));
            new (entryUserdata) LuaTrackEntry(L, track);

            return 1;
        }
    }

    return 0;
}

static int track_newindex(lua_State *L)
{
    return 0;
}

static int track_len(lua_State *L)
{
    LuaTrack *trackUserdata = (LuaTrack *)luaL_checkudata(L, 1, "SpineTrack");

    lua_pushinteger(L, trackUserdata->tracks.size());

    return 1;
}

static int track_gc(lua_State *L)
{
    LuaTrack *trackUserdata = (LuaTrack *)luaL_checkudata(L, 1, "SpineTrack");

    trackUserdata->~LuaTrack();

    return 0;
}

void getTrackMt(lua_State *L)
{
    if (luaL_newmetatable(L, "SpineTrack"))
    {
        lua_pushcfunction(L, track_index);
        lua_setfield(L, -2, "__index");

        lua_pushcfunction(L, track_newindex);
        lua_setfield(L, -2, "__newindex");

        lua_pushcfunction(L, track_len);
        lua_setfield(L, -2, "__len");

        lua_pushcfunction(L, track_gc);
        lua_setfield(L, -2, "__gc");
    }
}
