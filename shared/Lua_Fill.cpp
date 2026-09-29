#include "Lua_Fill.h"
#include "Lua_Skeleton.h"
#include "Lua_EffectData.h"
#include "Lua_FillEffect.h"

static int fill_index(lua_State *L)
{
    LuaFill *fillUserdata = (LuaFill *)luaL_checkudata(L, 1, "SpineFill");

    const char *key = luaL_checkstring(L, 2);

    if (!fillUserdata || !fillUserdata->owner || !fillUserdata->owner->skeleton)
    {
        return 0;
    }

    Skeleton &skeleton = *fillUserdata->owner->skeleton;

    if (strcmp(key, "r") == 0)
    {
        lua_pushnumber(L, skeleton.getColor().r);
        return 1;
    }
    else if (strcmp(key, "g") == 0)
    {
        lua_pushnumber(L, skeleton.getColor().g);
        return 1;
    }
    else if (strcmp(key, "b") == 0)
    {
        lua_pushnumber(L, skeleton.getColor().b);
        return 1;
    }
    else if (strcmp(key, "a") == 0)
    {
        lua_pushnumber(L, skeleton.getColor().a);
        return 1;
    }
    else if (strcmp(key, "effect") == 0)
    {
        if (!fillUserdata->owner->effectData)
        {
            lua_pushnil(L);
            return 1;
        }

        LuaFillEffect *ud = (LuaFillEffect *)lua_newuserdata(L, sizeof(LuaFillEffect));
        new (ud) LuaFillEffect(L, fillUserdata->owner);
        lua_getfenv(L, 1); // 1.2.6: same anchor as the parent wrapper (pins the skeleton)
        lua_setfenv(L, -2);
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

static int fill_newindex(lua_State *L)
{
    LuaFill *fillUserdata = (LuaFill *)luaL_checkudata(L, 1, "SpineFill");

    if (!fillUserdata->owner || !fillUserdata->owner->skeleton)
    {
        return 0;
    }

    Skeleton &skeleton = *fillUserdata->owner->skeleton;

    const char *key = luaL_checkstring(L, 2);

    if (strcmp(key, "r") == 0)
    {
        float r = luaL_checknumber(L, 3);
        skeleton.getColor().r = r;
        return 0;
    }
    else if (strcmp(key, "g") == 0)
    {
        float g = luaL_checknumber(L, 3);
        skeleton.getColor().g = g;
        return 0;
    }
    else if (strcmp(key, "b") == 0)
    {
        float b = luaL_checknumber(L, 3);
        skeleton.getColor().b = b;
        return 0;
    }
    else if (strcmp(key, "a") == 0)
    {
        float a = luaL_checknumber(L, 3);
        skeleton.getColor().a = a;
        return 0;
    }
    else if (strcmp(key, "effect") == 0)
    {
        if (lua_isnil(L, 3))
        {
            if (fillUserdata->owner->effectData)
            {
                delete fillUserdata->owner->effectData;
                fillUserdata->owner->effectData = nullptr;
            }
            fillUserdata->owner->onEffectUpdated("name", L, 3);
            return 0;
        }

        if (lua_isstring(L, 3))
        {
            const char *name = lua_tostring(L, 3);
            if (!fillUserdata->owner->effectData)
            {
                fillUserdata->owner->effectData = new Lua_EffectData();
            }
            fillUserdata->owner->effectData->setName(name);
            fillUserdata->owner->onEffectUpdated("name", L, 3);
            return 0;
        }

        luaL_error(L, "fill.effect expects nil or string (effect name)");
        return 0;
    }

    return 0;
}

static int fill_gc(lua_State *L)
{
    LuaFill *filldata = (LuaFill *)luaL_checkudata(L, 1, "SpineFill");

    // Explicitly call the placement-destructed object destructor.
    filldata->~LuaFill();

    return 0;
}

void getFillMt(lua_State *L)
{
    if (luaL_newmetatable(L, "SpineFill"))
    {
        lua_pushcfunction(L, fill_index);
        lua_setfield(L, -2, "__index");

        lua_pushcfunction(L, fill_newindex);
        lua_setfield(L, -2, "__newindex");

        lua_pushcfunction(L, fill_gc);
        lua_setfield(L, -2, "__gc");
    }
}
