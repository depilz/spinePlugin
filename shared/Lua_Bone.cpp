#include "Lua_Bone.h"

// The world helpers take skeleton-space coordinates (bone.worldX/worldY space). setWorldPosition/translateWorld write
// the local pose only: the world values follow on the next updateState or draw, and an animation keying the bone
// overwrites the write on its next apply.
static LuaBone &checkBone(lua_State *L)
{
    LuaBone *boneUserdata = (LuaBone *)luaL_checkudata(L, 1, "SpineBone");
    boneUserdata->checkAlive(L);
    return *boneUserdata;
}

static void setBoneWorldPosition(lua_State *L, LuaBone &boneUserdata, float worldX, float worldY)
{
    Bone &bone = *boneUserdata.bone;
    float localX, localY;

    if (Bone *parent = bone.getParent())
    {
        spc::applied(*parent).worldToLocal(worldX, worldY, localX, localY);
    }
    else
    {
        Skeleton &skeleton = *boneUserdata.skeleton;
        float scaleX = skeleton.getScaleX();
        float scaleY = skeleton.getScaleY();
        if (scaleX == 0 || scaleY == 0)
        {
            luaL_error(L, "Cannot set a root bone's world position when skeleton scale is zero");
            return;
        }

        localX = (worldX - skeleton.getX()) / scaleX;
        localY = (worldY - skeleton.getY()) / scaleY;
    }

    spc::pose(bone).setX(localX);
    spc::pose(bone).setY(localY);
}

// the world position of the bone's local pose, which may hold a write not yet applied
static void getPoseWorldPosition(LuaBone &boneUserdata, float &worldX, float &worldY)
{
    Bone &bone = *boneUserdata.bone;
    auto &pose = spc::pose(bone);

    if (Bone *parent = bone.getParent())
    {
        spc::applied(*parent).localToWorld(pose.getX(), pose.getY(), worldX, worldY);
    }
    else
    {
        Skeleton &skeleton = *boneUserdata.skeleton;
        worldX = pose.getX() * skeleton.getScaleX() + skeleton.getX();
        worldY = pose.getY() * skeleton.getScaleY() + skeleton.getY();
    }
}

// bone:setWorldPosition(worldX, worldY)
static int setWorldPosition(lua_State *L)
{
    LuaBone &boneUserdata = checkBone(L);
    setBoneWorldPosition(L, boneUserdata, luaL_checknumber(L, 2), luaL_checknumber(L, 3));
    return 0;
}

// bone:translateWorld(deltaX, deltaY)
static int translateWorld(lua_State *L)
{
    LuaBone &boneUserdata = checkBone(L);
    float deltaX = luaL_checknumber(L, 2);
    float deltaY = luaL_checknumber(L, 3);
    float worldX, worldY;
    getPoseWorldPosition(boneUserdata, worldX, worldY);
    setBoneWorldPosition(L, boneUserdata, worldX + deltaX, worldY + deltaY);
    return 0;
}

// bone:localToWorld(localX, localY) -> worldX, worldY
static int localToWorld(lua_State *L)
{
    LuaBone &boneUserdata = checkBone(L);
    float worldX, worldY;
    spc::applied(*boneUserdata.bone).localToWorld(luaL_checknumber(L, 2), luaL_checknumber(L, 3), worldX, worldY);
    lua_pushnumber(L, worldX);
    lua_pushnumber(L, worldY);
    return 2;
}

// bone:worldToLocal(worldX, worldY) -> localX, localY
static int worldToLocal(lua_State *L)
{
    LuaBone &boneUserdata = checkBone(L);
    float localX, localY;
    spc::applied(*boneUserdata.bone).worldToLocal(luaL_checknumber(L, 2), luaL_checknumber(L, 3), localX, localY);
    lua_pushnumber(L, localX);
    lua_pushnumber(L, localY);
    return 2;
}

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
            new (parentUserdata) LuaBone(L, parent, boneUserdata->skeleton, boneUserdata->alive);
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
            new (childUserdata) LuaBone(L, child, boneUserdata->skeleton, boneUserdata->alive);
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
    else if (strcmp(key, "scaleX") == 0 || strcmp(key, "xScale") == 0)
    {
        lua_pushnumber(L, spc::pose(bone).getScaleX());
        return 1;
    }
    else if (strcmp(key, "scaleY") == 0 || strcmp(key, "yScale") == 0)
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
    else if (strcmp(key, "scaleX") == 0 || strcmp(key, "xScale") == 0)
    {
        float xScale = luaL_checknumber(L, 3);
        spc::pose(bone).setScaleX(xScale);
        return 0;
    }
    else if (strcmp(key, "scaleY") == 0 || strcmp(key, "yScale") == 0)
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
    else if (strcmp(key, "worldX") == 0 || strcmp(key, "worldY") == 0)
    {
        return luaL_error(L, "%s is read-only; use bone:setWorldPosition(x, y)", key);
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

        lua_pushcfunction(L, setWorldPosition);
        lua_setfield(L, -2, "setWorldPosition");

        lua_pushcfunction(L, translateWorld);
        lua_setfield(L, -2, "translateWorld");

        lua_pushcfunction(L, localToWorld);
        lua_setfield(L, -2, "localToWorld");

        lua_pushcfunction(L, worldToLocal);
        lua_setfield(L, -2, "worldToLocal");
    }
}
