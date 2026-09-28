#pragma once

#include "CoronaLua.h"
#include "SkeletonLife.h"
#include "SpineCompat.h"
#include <memory>

using namespace spine;

void getEntryMt(lua_State* L);

// Validity token kept in the entry's renderer object. spine-cpp disposes it when the entry is reset for the pool
// (TrackEntry::reset -> setRendererObject(NULL)) and when the entry is deleted (~HasRendererObject), so every wrapper
// of a finished, pooled or deleted entry sees *valid == false.
struct TrackEntryToken
{
    std::shared_ptr<bool> valid = std::make_shared<bool>(true);
};

inline void disposeTrackEntryToken(void *token)
{
    TrackEntryToken *t = (TrackEntryToken *)token;
    *t->valid = false;
    delete t;
}

inline std::shared_ptr<bool> trackEntryToken(TrackEntry *entry)
{
    TrackEntryToken *t = (TrackEntryToken *)entry->getRendererObject();
    if (!t)
    {
        t = new TrackEntryToken();
        entry->setRendererObject(t, disposeTrackEntryToken);
    }
    return t->valid;
}

struct LuaTrackEntry
{
    lua_State *L;
    TrackEntry *entry;
    std::shared_ptr<SkeletonLife> alive; // the skeleton's
    std::shared_ptr<bool> valid; // the entry's (trackEntryToken)

    LuaTrackEntry(lua_State *L, TrackEntry *entry, std::shared_ptr<SkeletonLife> alive)
        : L(L), entry(entry), alive(alive), valid(trackEntryToken(entry))
    {
        getEntryMt(L);
        lua_setmetatable(L, -2);
    }

    bool isValid() const { return entry && *valid && (!alive || *alive); }

    void checkAlive(lua_State *state) const
    {
        if (alive && !*alive)
            luaL_error(state, "Track entry belongs to a removed skeleton");
        if (!isValid())
            luaL_error(state, "Track entry is no longer valid (finished or disposed); check entry.isValid");
    }

    ~LuaTrackEntry()
    {
        entry = nullptr;
        L = nullptr;
    }
};

