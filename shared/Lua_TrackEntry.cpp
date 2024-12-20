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

    if (strcmp(key, "timeScale") == 0)
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
        lua_pushnumber(L, entry.getDelay());
        return 1;
    }
    else if (strcmp(key, "trackTime") == 0) {
        lua_pushnumber(L, entry.getTrackTime());
        return 1;
    }
    else if (strcmp(key, "trackEnd") == 0) {
        lua_pushnumber(L, entry.getTrackEnd());
        return 1;
    }
    else if (strcmp(key, "animationStart") == 0) {
        lua_pushnumber(L, entry.getAnimationStart());
        return 1;
    }
    else if (strcmp(key, "animationLast") == 0) {
        lua_pushnumber(L, entry.getAnimationLast());
        return 1;
    }
    else if (strcmp(key, "animationTime") == 0) {
        lua_pushnumber(L, entry.getAnimationTime());
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

    if (strcmp(key, "timeScale") == 0)
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
        float delay = luaL_checknumber(L, 3);
        entry.setDelay(delay);
        return 0;
    }
    else if (strcmp(key, "trackTime") == 0) {
        float trackTime = luaL_checknumber(L, 3);
        entry.setTrackTime(trackTime);
        return 0;
    }
    else if (strcmp(key, "trackEnd") == 0) {
        float trackEnd = luaL_checknumber(L, 3);
        entry.setTrackEnd(trackEnd);
        return 0;
    }
    else if (strcmp(key, "animationStart") == 0) {
        float animationStart = luaL_checknumber(L, 3);
        entry.setAnimationStart(animationStart);
        return 0;
    }
    else if (strcmp(key, "animationEnd") == 0) {
        float animationEnd = luaL_checknumber(L, 3);
        entry.setAnimationEnd(animationEnd);
        return 0;
    }
    else if (strcmp(key, "animationLast") == 0) {
        float animationLast = luaL_checknumber(L, 3);
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
    luaL_getmetatable(L, "SpineTrackEntry");
    if (lua_isnil(L, -1))
    {
        lua_pop(L, 1);
        luaL_newmetatable(L, "SpineTrackEntry");

        lua_pushstring(L, "__index");
        lua_pushcfunction(L, entry_index);
        lua_settable(L, -3);

        lua_pushstring(L, "__newindex");
        lua_pushcfunction(L, entry_newindex);
        lua_settable(L, -3);

        lua_pushcfunction(L, entry_gc);
        lua_setfield(L, -2, "__gc");
    }
}
