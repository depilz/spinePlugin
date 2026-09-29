#include "Lua_TrackEntry.h"

// trackEntry:setMixDuration(mixDurationMs [, delayMs])
static int entry_setMixDuration(lua_State *L)
{
    LuaTrackEntry *entryUserdata = (LuaTrackEntry *)luaL_checkudata(L, 1, "SpineTrackEntry");
    entryUserdata->checkAlive(L);

    TrackEntry &entry = *entryUserdata->entry;
    float mixDuration = luaL_checknumber(L, 2) / 1000;

    if (lua_gettop(L) >= 3 && !lua_isnil(L, 3))
    {
        float delay = luaL_checknumber(L, 3) / 1000;
        entry.setMixDuration(mixDuration, delay);
    }
    else
    {
        entry.setMixDuration(mixDuration);
    }

    return 0;
}

static int entry_index(lua_State *L)
{
    LuaTrackEntry *entryUserdata = (LuaTrackEntry *)luaL_checkudata(L, 1, "SpineTrackEntry");
    const char *key = luaL_checkstring(L, 2);

    // readable on any entry: false once the entry finished, was pooled or its skeleton was removed
    if (strcmp(key, "isValid") == 0)
    {
        lua_pushboolean(L, entryUserdata->isValid());
        return 1;
    }
    entryUserdata->checkAlive(L);

    TrackEntry &entry = *entryUserdata->entry;

    if (strcmp(key, "index") == 0)
    {
        // Lua-facing track indices are 1-based.
        lua_pushinteger(L, entry.getTrackIndex() + 1);
        return 1;
    }
    else if (strcmp(key, "animation") == 0)
    {
        const char *animationName = spc::anim(entry).getName().buffer();
        lua_pushstring(L, animationName);

        return 1;
    }
    else if (strcmp(key, "shortestRotation") == 0)
    {
        lua_pushboolean(L, entry.getShortestRotation());
        return 1;
    }
    else if (strcmp(key, "alpha") == 0)
    {
        lua_pushnumber(L, entry.getAlpha());
        return 1;
    }
    else if (strcmp(key, "eventThreshold") == 0)
    {
        lua_pushnumber(L, entry.getEventThreshold());
        return 1;
    }
    else if (strcmp(key, "mixAttachmentThreshold") == 0)
    {
        lua_pushnumber(L, entry.getMixAttachmentThreshold());
        return 1;
    }
    else if (strcmp(key, "alphaAttachmentThreshold") == 0)
    {
        lua_pushnumber(L, entry.getAlphaAttachmentThreshold());
        return 1;
    }
    else if (strcmp(key, "mixDrawOrderThreshold") == 0)
    {
        lua_pushnumber(L, entry.getMixDrawOrderThreshold());
        return 1;
    }
    else if (strcmp(key, "mixTime") == 0)
    {
        lua_pushnumber(L, entry.getMixTime() * 1000);
        return 1;
    }
    else if (strcmp(key, "mixDuration") == 0)
    {
        lua_pushnumber(L, entry.getMixDuration() * 1000);
        return 1;
    }
    else if (strcmp(key, "trackComplete") == 0)
    {
        lua_pushnumber(L, entry.getTrackComplete() * 1000);
        return 1;
    }
    else if (strcmp(key, "timeScale") == 0)
    {
        lua_pushnumber(L, entry.getTimeScale());
        return 1;
    }
    else if (strcmp(key, "loop") == 0)
    {
        lua_pushboolean(L, entry.getLoop());
        return 1;
    }
    else if (strcmp(key, "isComplete") == 0) {
        lua_pushboolean(L, entry.isComplete());
        return 1;
    }
    else if (strcmp(key, "holdPrevious") == 0) {
        lua_pushboolean(L, entry.getHoldPrevious());
        return 1;
    }
    else if (strcmp(key, "reverse") == 0) {
        lua_pushboolean(L, entry.getReverse());
        return 1;
    }
    else if (strcmp(key, "delay") == 0) {
        lua_pushnumber(L, entry.getDelay() * 1000);
        return 1;
    }
    else if (strcmp(key, "trackTime") == 0) {
        lua_pushnumber(L, entry.getTrackTime() * 1000);
        return 1;
    }
    else if (strcmp(key, "trackEnd") == 0) {
        lua_pushnumber(L, entry.getTrackEnd() * 1000);
        return 1;
    }
    else if (strcmp(key, "animationStart") == 0) {
        lua_pushnumber(L, entry.getAnimationStart() * 1000);
        return 1;
    }
    else if (strcmp(key, "animationLast") == 0) {
        lua_pushnumber(L, entry.getAnimationLast() * 1000);
        return 1;
    }
    else if (strcmp(key, "animationTime") == 0) {
        lua_pushnumber(L, entry.getAnimationTime() * 1000);
        return 1;
    }
    else if (strcmp(key, "animationEnd") == 0)
    {
        lua_pushnumber(L, entry.getAnimationEnd() * 1000);
        return 1;
    }
    else if (strcmp(key, "next") == 0)
    {
        TrackEntry *nextEntry = entry.getNext();
        if (!nextEntry)
        {
            lua_pushnil(L);
            return 1;
        }

        pushTrackEntry(L, nextEntry, entryUserdata->alive);
        return 1;
    }
    else if (strcmp(key, "mixingFrom") == 0)
    {
        TrackEntry *mixingFrom = entry.getMixingFrom();
        if (!mixingFrom)
        {
            lua_pushnil(L);
            return 1;
        }

        pushTrackEntry(L, mixingFrom, entryUserdata->alive);
        return 1;
    }
    else if (strcmp(key, "onComplete") == 0)
    {
        lua_rawgeti(L, LUA_REGISTRYINDEX, trackEntryOnComplete(&entry)); // LUA_NOREF reads nil
        return 1;
    }
    else if (strcmp(key, "mixingTo") == 0)
    {
        TrackEntry *mixingTo = entry.getMixingTo();
        if (!mixingTo)
        {
            lua_pushnil(L);
            return 1;
        }

        pushTrackEntry(L, mixingTo, entryUserdata->alive);
        return 1;
    }

    // fallback to methods
    lua_getmetatable(L, 1);
    lua_pushvalue(L, 2);
    lua_rawget(L, -2);
    if (!lua_isnil(L, -1))
    {
        return 1;
    }

    return 0;
}

// The keys entry_index reads that entry_newindex does not write.
static const char *const readOnlyKeys[] = {"index", "animation", "trackComplete", "isComplete", "animationTime",
                                           "next", "mixingFrom", "mixingTo", "isValid", NULL};

static int entry_newindex(lua_State *L)
{
    LuaTrackEntry *entryUserdata = (LuaTrackEntry *)luaL_checkudata(L, 1, "SpineTrackEntry");
    entryUserdata->checkAlive(L);

    const char *key = luaL_checkstring(L, 2);

    TrackEntry &entry = *entryUserdata->entry;

    if (strcmp(key, "shortestRotation") == 0)
    {
        bool shortestRotation = lua_toboolean(L, 3);
        entry.setShortestRotation(shortestRotation);
        return 0;
    }
    else if (strcmp(key, "alpha") == 0) 
    {
        float alpha = luaL_checknumber(L, 3);
        entry.setAlpha(alpha);
        return 0;
    }
    else if (strcmp(key, "eventThreshold") == 0)
    {
        float eventThreshold = luaL_checknumber(L, 3);
        entry.setEventThreshold(eventThreshold);
        return 0;
    }
    else if (strcmp(key, "mixAttachmentThreshold") == 0)
    {
        float mixAttachmentThreshold = luaL_checknumber(L, 3);
        entry.setMixAttachmentThreshold(mixAttachmentThreshold);
        return 0;
    }
    else if (strcmp(key, "timeScale") == 0)
    {
        float timeScale = luaL_checknumber(L, 3);
        entry.setTimeScale(timeScale);
        return 0;
    }
    else if (strcmp(key, "loop") == 0)
    {
        bool loop = lua_toboolean(L, 3);
        entry.setLoop(loop);
        return 0;
    }
    else if (strcmp(key, "holdPrevious") == 0) {
        bool holdPrevious = lua_toboolean(L, 3);
        entry.setHoldPrevious(holdPrevious);
        return 0;
    }
    else if (strcmp(key, "reverse") == 0) {
        bool reverse = lua_toboolean(L, 3);
        entry.setReverse(reverse);
        return 0;
    }
    else if (strcmp(key, "delay") == 0) {
        float delay = luaL_checknumber(L, 3) / 1000;
        entry.setDelay(delay);
        return 0;
    }
    else if (strcmp(key, "trackTime") == 0) {
        float trackTime = luaL_checknumber(L, 3) / 1000;
        entry.setTrackTime(trackTime);
        return 0;
    }
    else if (strcmp(key, "trackEnd") == 0) {
        float trackEnd = luaL_checknumber(L, 3) / 1000;
        entry.setTrackEnd(trackEnd);
        return 0;
    }
    else if (strcmp(key, "alphaAttachmentThreshold") == 0) {
        float alphaAttachmentThreshold = luaL_checknumber(L, 3);
        entry.setAlphaAttachmentThreshold(alphaAttachmentThreshold);
        return 0;
    }
    else if (strcmp(key, "mixDrawOrderThreshold") == 0) {
        float mixDrawOrderThreshold = luaL_checknumber(L, 3);
        entry.setMixDrawOrderThreshold(mixDrawOrderThreshold);
        return 0;
    }
    else if (strcmp(key, "mixTime") == 0)
    {
        float mixTime = luaL_checknumber(L, 3) / 1000;
        entry.setMixTime(mixTime);
        return 0;
    }
    else if (strcmp(key, "mixDuration") == 0)
    {
        float mixDuration = luaL_checknumber(L, 3) / 1000;
        entry.setMixDuration(mixDuration);
        return 0;
    }
    else if (strcmp(key, "animationStart") == 0) {
        float animationStart = luaL_checknumber(L, 3) / 1000;
        entry.setAnimationStart(animationStart);
        return 0;
    }
    else if (strcmp(key, "animationEnd") == 0) {
        float animationEnd = luaL_checknumber(L, 3) / 1000;
        entry.setAnimationEnd(animationEnd);
        return 0;
    }
    else if (strcmp(key, "animationLast") == 0) {
        float animationLast = luaL_checknumber(L, 3) / 1000;
        entry.setAnimationLast(animationLast);
        return 0;
    }
    else if (strcmp(key, "onComplete") == 0)
    {
        if (!lua_isnil(L, 3)) luaL_checktype(L, 3, LUA_TFUNCTION);
        lua_settop(L, 3);
        int ref = lua_isnil(L, 3) ? LUA_NOREF : luaL_ref(L, LUA_REGISTRYINDEX);
        // a valid entry always has its token: the wrapper's constructor installed it
        ((TrackEntryToken *)entry.getRendererObject())->setOnComplete(L, ref);
        return 0;
    }

    for (const char *const *readOnly = readOnlyKeys; *readOnly; readOnly++)
    {
        if (strcmp(key, *readOnly) == 0)
            return luaL_error(L, "SpineTrackEntry: property '%s' is read-only", key);
    }
    return luaL_error(L, "SpineTrackEntry: unknown property '%s'", key);
}

// Wrappers are equal iff they wrap the same entry: the same token, whose valid flag they share (the raw pointer is
// reused by the pool). Lua calls __eq only for two SpineTrackEntry userdata; it never raises, stale wrappers included.
static int entry_eq(lua_State *L)
{
    LuaTrackEntry *a = (LuaTrackEntry *)lua_touserdata(L, 1);
    LuaTrackEntry *b = (LuaTrackEntry *)lua_touserdata(L, 2);
    lua_pushboolean(L, a->valid == b->valid);
    return 1;
}

static int entry_gc(lua_State *L)
{
    LuaTrackEntry *entryUserdata = (LuaTrackEntry *)luaL_checkudata(L, 1, "SpineTrackEntry");

    entryUserdata->~LuaTrackEntry();

    return 0;
}

void getEntryMt(lua_State *L)
{
    if (luaL_newmetatable(L, "SpineTrackEntry"))
    {
        lua_pushcfunction(L, entry_index);
        lua_setfield(L, -2, "__index");

        lua_pushcfunction(L, entry_newindex);
        lua_setfield(L, -2, "__newindex");

        lua_pushcfunction(L, entry_gc);
        lua_setfield(L, -2, "__gc");

        lua_pushcfunction(L, entry_eq);
        lua_setfield(L, -2, "__eq");

        lua_pushcfunction(L, entry_setMixDuration);
        lua_setfield(L, -2, "setMixDuration");
    }
}
