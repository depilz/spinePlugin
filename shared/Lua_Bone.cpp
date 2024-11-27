#include "Lua_Bone.h"

static int bone_index(lua_State *L)
{
    LuaBone *boneUserdata = (LuaBone *)luaL_checkudata(L, 1, "SpineBone");

    if (!boneUserdata->bone)
    {
        return 0;
    }

    const char *key = luaL_checkstring(L, 2);

    Bone &bone = *boneUserdata->bone;

    if (strcmp(key, "name") == 0)
    {
        lua_pushstring(L, bone.getData().getName().buffer());
        return 1;
    }
    else if (strcmp(key, "parent") == 0)
    {
        Bone *parent = bone.getParent();
        if (parent)
        {
            LuaBone *boneUserdata = (LuaBone *)lua_newuserdata(L, sizeof(LuaBone));
            new (boneUserdata) LuaBone(L, parent);
        }
        else
        {
            lua_pushnil(L);
        }
        return 1;
    }
    else if (strcmp(key, "x") == 0)
    {
        lua_pushnumber(L, bone.getX());
        return 1;
    }
    else if (strcmp(key, "y") == 0)
    {
        lua_pushnumber(L, -bone.getY());
        return 1;
    }
    else if (strcmp(key, "rotation") == 0)
    {
        lua_pushnumber(L, -bone.getRotation());
        return 1;
    }
    else if (strcmp(key, "xScale") == 0)
    {
        lua_pushnumber(L, bone.getScaleX());
        return 1;
    }
    else if (strcmp(key, "yScale") == 0)
    {
        lua_pushnumber(L, bone.getScaleY());
        return 1;
    }
    else if (strcmp(key, "shearX") == 0)
    {
        lua_pushnumber(L, bone.getShearX());
        return 1;
    }
    else if (strcmp(key, "shearY") == 0)
    {
        lua_pushnumber(L, bone.getShearY());
        return 1;
    }
    else if (strcmp(key, "appliedRotation") == 0)
    {
        lua_pushnumber(L, -bone.getAppliedRotation());
        return 1;
    }
    else if (strcmp(key, "worldX") == 0)
    {
        lua_pushnumber(L, bone.getWorldX());
        return 1;
    }
    else if (strcmp(key, "worldY") == 0)
    {
        lua_pushnumber(L, bone.getWorldY());
        return 1;
    }
    else if (strcmp(key, "worldRotation") == 0)
    {
        lua_pushnumber(L, -bone.getWorldRotationX());
        return 1;
    }
    else if (strcmp(key, "worldScaleX") == 0)
    {
        lua_pushnumber(L, bone.getWorldScaleX());
        return 1;
    }
    else if (strcmp(key, "worldScaleY") == 0)
    {
        lua_pushnumber(L, -bone.getWorldScaleY());
        return 1;
    }
    else if (strcmp(key, "a") == 0)
    {
        lua_pushnumber(L, bone.getA());
        return 1;
    }
    else if (strcmp(key, "b") == 0)
    {
        lua_pushnumber(L, bone.getB());
        return 1;
    }
    else if (strcmp(key, "c") == 0)
    {
        lua_pushnumber(L, bone.getC());
        return 1;
    }
    else if (strcmp(key, "d") == 0)
    {
        lua_pushnumber(L, bone.getD());
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

static int bone_newindex(lua_State *L)
{
    LuaBone *boneUserdata = (LuaBone *)luaL_checkudata(L, 1, "SpineBone");

    if (!boneUserdata->bone)
    {
        return 0;
    }

    const char *key = luaL_checkstring(L, 2);

    Bone &bone = *boneUserdata->bone;

    if (strcmp(key, "x") == 0)
    {
        float x = luaL_checknumber(L, 3);
        bone.setX(x);
        return 0;
    }
    else if (strcmp(key, "y") == 0)
    {
        float y = luaL_checknumber(L, 3);
        bone.setY(-y);
        return 0;
    }
    else if (strcmp(key, "rotation") == 0)
    {
        float rotation = luaL_checknumber(L, 3);
        bone.setRotation(-rotation);
        return 0;
    }
    else if (strcmp(key, "xScale") == 0)
    {
        float xScale = luaL_checknumber(L, 3);
        bone.setScaleX(xScale);
        return 0;
    }
    else if (strcmp(key, "yScale") == 0)
    {
        float yScale = luaL_checknumber(L, 3);
        bone.setScaleY(yScale);
        return 0;
    }
    else if (strcmp(key, "shearX") == 0)
    {
        float xShear = luaL_checknumber(L, 3);
        bone.setShearX(xShear);
        return 0;
    }
    else if (strcmp(key, "shearY") == 0)
    {
        float yShear = luaL_checknumber(L, 3);
        bone.setShearY(yShear);
        return 0;
    }
    else if (strcmp(key, "appliedRotation") == 0)
    {
        float appliedRotation = luaL_checknumber(L, 3);
        bone.setAppliedRotation(-appliedRotation);
        return 0;
    }
    else if (strcmp(key, "a") == 0)
    {
        float a = luaL_checknumber(L, 3);
        bone.setA(a);
        return 0;
    }
    else if (strcmp(key, "b") == 0)
    {
        float b = luaL_checknumber(L, 3);
        bone.setB(b);
        return 0;
    }
    else if (strcmp(key, "c") == 0)
    {
        float c = luaL_checknumber(L, 3);
        bone.setC(c);
        return 0;
    }
    else if (strcmp(key, "d") == 0)
    {
        float d = luaL_checknumber(L, 3);
        bone.setD(d);
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

static int bone_gc(lua_State *L)
{
    LuaBone *boneUserdata = (LuaBone *)luaL_checkudata(L, 1, "SpineBone");

    boneUserdata->~LuaBone();

    return 0;
}

void getBoneMt(lua_State *L)
{
    luaL_getmetatable(L, "SpineBone");
    if (lua_isnil(L, -1))
    {
        lua_pop(L, 1);
        luaL_newmetatable(L, "SpineBone");

        lua_pushstring(L, "__index");
        lua_pushcfunction(L, bone_index);
        lua_settable(L, -3);

        lua_pushstring(L, "__newindex");
        lua_pushcfunction(L, bone_newindex);
        lua_settable(L, -3);

        lua_pushcfunction(L, bone_gc);
        lua_setfield(L, -2, "__gc");
    }
}
