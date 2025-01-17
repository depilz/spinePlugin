#include "Lua_TrackEntry.h"

static int entry_index(lua_State *L)
{
    LuaTrackEntry *entryUserdata = (LuaTrackEntry *)luaL_checkudata(L, 1, "SpineTrackEntry");

    if (!entryUserdata->entry)
    {
        return 0;
    }


    const char *key = luaL_checkstring(L, 2);

    TrackEntry &entry = *entryUserdata->entry;

    if (strcmp(key, "index") == 0)
    {
        lua_pushnumber(L, entry.getTrackIndex());
        return 1;
    }
    else if (strcmp(key, "animation") == 0)
    {
        const char *animationName = entry.getAnimation()->getName().buffer();
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
    else if (strcmp(key, "timeScale") == 0)
    {
        lua_pushnumber(L, entry.getTimeScale() * 1000);
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

static int entry_newindex(lua_State *L)
{
    LuaTrackEntry *entryUserdata = (LuaTrackEntry *)luaL_checkudata(L, 1, "SpineTrackEntry");

    if (!entryUserdata->entry)
    {
        return 0;
    }

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
        float timeScale = luaL_checknumber(L, 3) / 1000;
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
        bool holdPrevious = lua_toboolean(L, 3) / 1000;
        entry.setHoldPrevious(holdPrevious);
        return 0;
    }
    else if (strcmp(key, "reverse") == 0) {
        bool reverse = lua_toboolean(L, 3) / 1000;
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
    }
}
