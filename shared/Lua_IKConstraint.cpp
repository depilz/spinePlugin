#include "Lua_IKConstraint.h"
#include "Lua_Bone.h"

static int ikConstraint_index(lua_State *L)
{
    LuaIKConstraint *ikConstraintUserdata = (LuaIKConstraint *)luaL_checkudata(L, 1, "SpineIKConstraint");

    if (!ikConstraintUserdata->ikConstraint)
    {
        return 0;
    }

    const char *key = luaL_checkstring(L, 2);
    
    if (strcmp(key, "name") == 0)
    {
        lua_pushstring(L, ikConstraintUserdata->ikConstraint->getData().getName().buffer());
        return 1;
    }
    else if (strcmp(key, "bones") == 0)
    {
        auto &bones = ikConstraintUserdata->ikConstraint->getBones();

        lua_createtable(L, static_cast<int>(bones.size()), 0);

        for (size_t i = 0; i < bones.size(); i++)
        {
            LuaBone *boneUserdata = (LuaBone *)lua_newuserdata(L, sizeof(LuaBone));
            new (boneUserdata) LuaBone(L, spc::boneOf(bones[i]));

            lua_rawseti(L, -2, static_cast<int>(i + 1));
        }

        return 1;
    }
    else if (strcmp(key, "isActive") == 0)
    {
        lua_pushboolean(L, ikConstraintUserdata->ikConstraint->isActive());
        return 1;
    }
    else if (strcmp(key, "mix") == 0)
    {
        lua_pushnumber(L, spc::pose(*ikConstraintUserdata->ikConstraint).getMix());
        return 1;
    }
    else if (strcmp(key, "stretch") == 0)
    {
        lua_pushboolean(L, spc::pose(*ikConstraintUserdata->ikConstraint).getStretch());
        return 1;
    }
    else if (strcmp(key, "softness") == 0)
    {
        lua_pushnumber(L, spc::pose(*ikConstraintUserdata->ikConstraint).getSoftness());
        return 1;
    }
    else if (strcmp(key, "bendDirection") == 0)
    {
        lua_pushinteger(L, spc::pose(*ikConstraintUserdata->ikConstraint).getBendDirection());
        return 1;
    }
    else if (strcmp(key, "compress") == 0)
    {
        lua_pushboolean(L, spc::pose(*ikConstraintUserdata->ikConstraint).getCompress());
        return 1;
    }
    else if (strcmp(key, "order") == 0)
    {
        lua_pushinteger(L, ikConstraintUserdata->ikConstraint->getOrder());
        return 1;
    }
    else if (strcmp(key, "target") == 0)
    {
        Bone *target = spc::ikTarget(*ikConstraintUserdata->ikConstraint);
        if (target)
        {
            LuaBone *boneUserdata = (LuaBone *)lua_newuserdata(L, sizeof(LuaBone));
            new (boneUserdata) LuaBone(L, target);
        }
        else
        {
            lua_pushnil(L);
        }

        return 1;
    }

    return 0;
}

static int ikConstraint_newindex(lua_State *L)
{
    LuaIKConstraint *ikConstraintUserdata = (LuaIKConstraint *)luaL_checkudata(L, 1, "SpineIKConstraint");

    if (!ikConstraintUserdata->ikConstraint)
    {
        return 0;
    }

    const char *key = luaL_checkstring(L, 2);

    if (strcmp(key, "target") == 0)
    {
        LuaBone *boneUserdata = (LuaBone *)luaL_checkudata(L, 3, "SpineBone");
        spc::setIkTarget(*ikConstraintUserdata->ikConstraint, boneUserdata->bone);
        return 0;
    }
    else if (strcmp(key, "isActive") == 0)
    {
        bool isActive = lua_toboolean(L, 3);
        ikConstraintUserdata->ikConstraint->setActive(isActive);
        return 0;
    }
    else if (strcmp(key, "mix") == 0)
    {
        float mix = luaL_checknumber(L, 3);
        spc::pose(*ikConstraintUserdata->ikConstraint).setMix(mix);
        return 0;
    }
    else if (strcmp(key, "stretch") == 0)
    {
        bool stretch = lua_toboolean(L, 3);
        spc::pose(*ikConstraintUserdata->ikConstraint).setStretch(stretch);
        return 0;
    }
    else if (strcmp(key, "softness") == 0)
    {
        float softness = luaL_checknumber(L, 3);
        spc::pose(*ikConstraintUserdata->ikConstraint).setSoftness(softness);
        return 0;
    }
    else if (strcmp(key, "bendDirection") == 0)
    {
        int bendDirection = static_cast<int>(luaL_checkinteger(L, 3));
        spc::pose(*ikConstraintUserdata->ikConstraint).setBendDirection(bendDirection);
        return 0;
    }
    else if (strcmp(key, "compress") == 0)
    {
        bool compress = lua_toboolean(L, 3);
        spc::pose(*ikConstraintUserdata->ikConstraint).setCompress(compress);
        return 0;
    }

    return 0;
}

static int ikConstraint_gc(lua_State *L)
{
    LuaIKConstraint *ikConstraintUserdata = (LuaIKConstraint *)luaL_checkudata(L, 1, "SpineIKConstraint");

    ikConstraintUserdata->~LuaIKConstraint();

    return 0;
}

void getIKConstraintMt(lua_State *L)
{
    if (luaL_newmetatable(L, "SpineIKConstraint"))
    {
        lua_pushcfunction(L, ikConstraint_index);
        lua_setfield(L, -2, "__index");

        lua_pushcfunction(L, ikConstraint_newindex);
        lua_setfield(L, -2, "__newindex");

        lua_pushcfunction(L, ikConstraint_gc);
        lua_setfield(L, -2, "__gc");
    }
}
