#include "Lua_Bone.h"

static int bone_index(lua_State *L)
{
    LuaBone *boneUserdata = (LuaBone *)luaL_checkudata(L, 1, "SpineBone");
    boneUserdata->checkAlive(L);

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
            LuaBone *parentUserdata = (LuaBone *)lua_newuserdata(L, sizeof(LuaBone));
            new (parentUserdata) LuaBone(L, parent, boneUserdata->alive);
        }
        else
        {
            lua_pushnil(L);
        }
        return 1;
    }
    else if (strcmp(key, "children") == 0)
    {
        lua_newtable(L);
        Vector<Bone *> &children = bone.getChildren();
        for (int i = 0; i < children.size(); i++)
        {
            Bone *child = children[i];
            LuaBone *childUserdata = (LuaBone *)lua_newuserdata(L, sizeof(LuaBone));
            new (childUserdata) LuaBone(L, child, boneUserdata->alive);
            lua_rawseti(L, -2, i + 1);
        }
        return 1;
    }
    else if (strcmp(key, "x") == 0)
    {
        lua_pushnumber(L, spc::pose(bone).getX());
        return 1;
    }
    else if (strcmp(key, "y") == 0)
    {
        lua_pushnumber(L, spc::pose(bone).getY());
        return 1;
    }
    else if (strcmp(key, "rotation") == 0)
    {
        lua_pushnumber(L, spc::pose(bone).getRotation());
        return 1;
    }
    else if (strcmp(key, "xScale") == 0)
    {
        lua_pushnumber(L, spc::pose(bone).getScaleX());
        return 1;
    }
    else if (strcmp(key, "yScale") == 0)
    {
        lua_pushnumber(L, spc::pose(bone).getScaleY());
        return 1;
    }
    else if (strcmp(key, "shearX") == 0)
    {
        lua_pushnumber(L, spc::pose(bone).getShearX());
        return 1;
    }
    else if (strcmp(key, "shearY") == 0)
    {
        lua_pushnumber(L, spc::pose(bone).getShearY());
        return 1;
    }
    else if (strcmp(key, "appliedRotation") == 0)
    {
        lua_pushnumber(L, spc::appliedRotation(bone));
        return 1;
    }
    else if (strcmp(key, "worldX") == 0)
    {
        lua_pushnumber(L, spc::applied(bone).getWorldX());
        return 1;
    }
    else if (strcmp(key, "worldY") == 0)
    {
        lua_pushnumber(L, spc::applied(bone).getWorldY());
        return 1;
    }
    else if (strcmp(key, "worldRotation") == 0)
    {
        lua_pushnumber(L, spc::applied(bone).getWorldRotationX());
        return 1;
    }
    else if (strcmp(key, "worldScaleX") == 0)
    {
        lua_pushnumber(L, spc::applied(bone).getWorldScaleX());
        return 1;
    }
    else if (strcmp(key, "worldScaleY") == 0)
    {
        lua_pushnumber(L, spc::applied(bone).getWorldScaleY());
        return 1;
    }
    else if (strcmp(key, "a") == 0)
    {
        lua_pushnumber(L, spc::applied(bone).getA());
        return 1;
    }
    else if (strcmp(key, "b") == 0)
    {
        lua_pushnumber(L, spc::applied(bone).getB());
        return 1;
    }
    else if (strcmp(key, "c") == 0)
    {
        lua_pushnumber(L, spc::applied(bone).getC());
        return 1;
    }
    else if (strcmp(key, "d") == 0)
    {
        lua_pushnumber(L, spc::applied(bone).getD());
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
    boneUserdata->checkAlive(L);

    const char *key = luaL_checkstring(L, 2);

    Bone &bone = *boneUserdata->bone;

    if (strcmp(key, "x") == 0)
    {
        float x = luaL_checknumber(L, 3);
        spc::pose(bone).setX(x);
        return 0;
    }
    else if (strcmp(key, "y") == 0)
    {
        float y = luaL_checknumber(L, 3);
        spc::pose(bone).setY(y);
        return 0;
    }
    else if (strcmp(key, "rotation") == 0)
    {
        float rotation = luaL_checknumber(L, 3);
        spc::pose(bone).setRotation(rotation);
        return 0;
    }
    else if (strcmp(key, "xScale") == 0)
    {
        float xScale = luaL_checknumber(L, 3);
        spc::pose(bone).setScaleX(xScale);
        return 0;
    }
    else if (strcmp(key, "yScale") == 0)
    {
        float yScale = luaL_checknumber(L, 3);
        spc::pose(bone).setScaleY(yScale);
        return 0;
    }
    else if (strcmp(key, "shearX") == 0)
    {
        float xShear = luaL_checknumber(L, 3);
        spc::pose(bone).setShearX(xShear);
        return 0;
    }
    else if (strcmp(key, "shearY") == 0)
    {
        float yShear = luaL_checknumber(L, 3);
        spc::pose(bone).setShearY(yShear);
        return 0;
    }
    else if (strcmp(key, "appliedRotation") == 0)
    {
        float appliedRotation = luaL_checknumber(L, 3);
        spc::setAppliedRotation(bone, appliedRotation);
        return 0;
    }
    else if (strcmp(key, "a") == 0)
    {
        float a = luaL_checknumber(L, 3);
        spc::applied(bone).setA(a);
        return 0;
    }
    else if (strcmp(key, "b") == 0)
    {
        float b = luaL_checknumber(L, 3);
        spc::applied(bone).setB(b);
        return 0;
    }
    else if (strcmp(key, "c") == 0)
    {
        float c = luaL_checknumber(L, 3);
        spc::applied(bone).setC(c);
        return 0;
    }
    else if (strcmp(key, "d") == 0)
    {
        float d = luaL_checknumber(L, 3);
        spc::applied(bone).setD(d);
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
