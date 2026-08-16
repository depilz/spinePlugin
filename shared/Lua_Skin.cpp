#include "Lua_Skin.h"

// skin:addSkin(otherSkin)
static int skin_addSkin(lua_State* L)
{
    LuaSkin* skinUserdata =
        (LuaSkin*)luaL_checkudata(L, 1, "SpineSkin");

    LuaSkin* otherSkinUserdata =
        (LuaSkin*)luaL_checkudata(L, 2, "SpineSkin");

    if (!skinUserdata->skin)
    {
        return luaL_error(L, "SpineSkin is null");
    }

    if (!otherSkinUserdata->skin)
    {
        return luaL_error(L, "Other SpineSkin is null");
    }

    skinUserdata->skin->addSkin(
        otherSkinUserdata->skin
    );

    return 0;
}

// skin:copySkin(otherSkin)
static int skin_copySkin(lua_State* L)
{
    LuaSkin* skinUserdata =
        (LuaSkin*)luaL_checkudata(
            L,
            1,
            "SpineSkin"
        );

    LuaSkin* otherSkinUserdata =
        (LuaSkin*)luaL_checkudata(
            L,
            2,
            "SpineSkin"
        );

    if (!skinUserdata->skin)
    {
        return luaL_error(
            L,
            "SpineSkin is null"
        );
    }

    if (!otherSkinUserdata->skin)
    {
        return luaL_error(
            L,
            "Other SpineSkin is null"
        );
    }

    skinUserdata->skin->copySkin(
        otherSkinUserdata->skin
    );

    return 0;
}

static int skin_index(lua_State* L)
{
    LuaSkin* skinUserdata = (LuaSkin*)luaL_checkudata(L, 1, "SpineSkin");

    if (!skinUserdata->skin)
    {
        return 0;
    }

    const char* key = luaL_checkstring(L, 2);

    Skin& skin = *skinUserdata->skin;

    // skin.name
    if (strcmp(key, "name") == 0)
    {
        lua_pushstring(
            L,
            skin.getName().buffer()
        );

        return 1;
    }

    // skin.color
    //
    // Lua:
    // local color = skin.color
    // print(color.r, color.g, color.b, color.a)
    else if (strcmp(key, "color") == 0)
    {
        Color& color = skin.getColor();

        lua_createtable(L, 0, 4);

        lua_pushnumber(L, color.r);
        lua_setfield(L, -2, "r");

        lua_pushnumber(L, color.g);
        lua_setfield(L, -2, "g");

        lua_pushnumber(L, color.b);
        lua_setfield(L, -2, "b");

        lua_pushnumber(L, color.a);
        lua_setfield(L, -2, "a");

        return 1;
    }
    else if (strcmp(key, "addSkin") == 0) 
    { 
        lua_pushcfunction(L, skin_addSkin); 
        return 1; 
    }
    else if (strcmp(key, "copySkin") == 0)
    {
        lua_pushcfunction(L, skin_copySkin);
        return 1;
    }
    lua_pushnil(L);
	return 1;
}

static int skin_newindex(lua_State* L)
{
    LuaSkin* skinUserdata = (LuaSkin*)luaL_checkudata(L, 1, "SpineSkin");

    if (!skinUserdata->skin)
    {
        return 0;
    }

    const char* key = luaL_checkstring(L, 2);

    Skin& skin = *skinUserdata->skin;

    return 0;
}

static int skin_gc(lua_State* L)
{
    LuaSkin* skinUserdata = (LuaSkin*)luaL_checkudata(L, 1, "SpineSkin");

    skinUserdata->~LuaSkin();

    return 0;
}


void getSkinMt(lua_State* L)
{
    luaL_getmetatable(L, "SpineSkin");
    if (lua_isnil(L, -1))
    {
        lua_pop(L, 1);
        luaL_newmetatable(L, "SpineSkin");

        lua_pushstring(L, "__index");
        lua_pushcfunction(L, skin_index);
        lua_settable(L, -3);

        lua_pushstring(L, "__newindex");
        lua_pushcfunction(L, skin_newindex);
        lua_settable(L, -3);

        lua_pushcfunction(L, skin_gc);
        lua_setfield(L, -2, "__gc");
    }
}