#include "Lua_Track.h"
#include "Lua_TrackEntry.h"

void pushTracks(lua_State *L, Vector<TrackEntry *> &tracks, std::shared_ptr<SkeletonLife> alive)
{
    int count = (int)tracks.size();
    lua_createtable(L, count, 0);
    for (int i = 0; i < count; i++)
    {
        if (tracks[i])
            pushTrackEntry(L, tracks[i], alive);
        else
            lua_pushboolean(L, 0);
        lua_rawseti(L, -2, i + 1);
    }
}
