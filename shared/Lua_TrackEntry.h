#pragma once

#include "CoronaLua.h"
#include "SkeletonLife.h"
#include "SpineCompat.h"
#include <memory>

using namespace spine;

void getEntryMt(lua_State* L);

// Validity token kept in the entry's renderer object. spine-cpp disposes it when the entry is reset for the pool
// (TrackEntry::reset -> setRendererObject(NULL)) and when the entry is deleted (~HasRendererObject), so every wrapper
// of a finished, pooled or deleted entry sees *valid == false, and a recycled entry starts without onComplete.
struct TrackEntryToken
{
    std::shared_ptr<bool> valid = std::make_shared<bool>(true);
    lua_State *mainState = nullptr; // the state onComplete is referenced in
    int onComplete = LUA_NOREF;     // registry ref to entry.onComplete, called by the state listener on complete

    // Takes over a registry ref (LUA_NOREF: none) and releases the previous one; a running call keeps its function.
    void setOnComplete(lua_State *L, int ref)
    {
        if (onComplete != LUA_NOREF) luaL_unref(mainState, LUA_REGISTRYINDEX, onComplete);
        mainState = CoronaLuaGetCoronaThread(L);
        onComplete = ref;
    }
};

inline void disposeTrackEntryToken(void *token)
{
    TrackEntryToken *t = (TrackEntryToken *)token;
    *t->valid = false;
    if (t->onComplete != LUA_NOREF) luaL_unref(t->mainState, LUA_REGISTRYINDEX, t->onComplete);
    delete t;
}

// The registry ref to entry.onComplete, or LUA_NOREF (none set, or the entry was never wrapped).
inline int trackEntryOnComplete(TrackEntry *entry)
{
    TrackEntryToken *t = (TrackEntryToken *)entry->getRendererObject();
    return t ? t->onComplete : LUA_NOREF;
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

// Pushes a new wrapper for entry (with the entry metatable) onto the stack.
inline void pushTrackEntry(lua_State *L, TrackEntry *entry, std::shared_ptr<SkeletonLife> alive)
{
    LuaTrackEntry *entryUserdata = (LuaTrackEntry *)lua_newuserdata(L, sizeof(LuaTrackEntry));
    new (entryUserdata) LuaTrackEntry(L, entry, alive);
}
