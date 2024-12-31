#include "Lua_Physics.h"

// physics:translate(x, y)
static int translate(lua_State *L)
{
    LuaPhysics *physicsUserdata = (LuaPhysics *)luaL_checkudata(L, 1, "SpinePhysics");

    if (!physicsUserdata)
    {
        return 0;
    }

    float x = luaL_checknumber(L, 2);
    float y = -luaL_checknumber(L, 3);

    Vector<PhysicsConstraint *> &PhysicsConstraints = physicsUserdata->constraints;

    for (int i = 0; i < PhysicsConstraints.size(); i++)
    {
        PhysicsConstraints[i]->translate(x, y);
    }

    return 0;
}


// physics:rotate(x, y, degrees)
static int rotate(lua_State *L)
{
    LuaPhysics *physicsUserdata = (LuaPhysics *)luaL_checkudata(L, 1, "SpinePhysics");

    if (!physicsUserdata)
    {
        return 0;
    }

    float x = luaL_checknumber(L, 2);
    float y = -luaL_checknumber(L, 3);
    float degrees = luaL_checknumber(L, 4);

    Vector<PhysicsConstraint *> &PhysicsConstraints = physicsUserdata->constraints;

    for (int i = 0; i < PhysicsConstraints.size(); i++)
    {
        PhysicsConstraints[i]->rotate(x, y, degrees);
    }

    return 0;
}

static int physics_index(lua_State *L)
{
    LuaPhysics *physicsUserdata = (LuaPhysics *)luaL_checkudata(L, 1, "SpinePhysics");

    if (!physicsUserdata)
    {
        return 0;
    }

    const char *key = luaL_checkstring(L, 2);
    Vector<PhysicsConstraint *> &PhysicsConstraints = physicsUserdata->constraints;

    if (strcmp(key, "wind") == 0)
    {
        lua_pushnumber(L, PhysicsConstraints[0]->getWind());
        return 1;
    } else if (strcmp(key, "inertia") == 0)
    {
        lua_pushnumber(L, PhysicsConstraints[0]->getInertia());
        return 1;
    } else if (strcmp(key, "strength") == 0)
    {
        lua_pushnumber(L, PhysicsConstraints[0]->getStrength());
        return 1;
    } else if (strcmp(key, "damping") == 0)
    {
        lua_pushnumber(L, PhysicsConstraints[0]->getDamping());
        return 1;
    } else if (strcmp(key, "massInverse") == 0)
    {
        lua_pushnumber(L, PhysicsConstraints[0]->getMassInverse());
        return 1;
    } else if (strcmp(key, "gravity") == 0)
    {
        lua_pushnumber(L, PhysicsConstraints[0]->getGravity());
        return 1;
    } else if (strcmp(key, "mix") == 0)
    {
        lua_pushnumber(L, PhysicsConstraints[0]->getMix());
        return 1;
    } else if (strcmp(key, "xVelocity") == 0)
    {
        lua_pushnumber(L, PhysicsConstraints[0]->getXVelocity());
        return 1;
    } else if (strcmp(key, "yVelocity") == 0)
    {
        lua_pushnumber(L, PhysicsConstraints[0]->getYVelocity());
        return 1;
    } else if (strcmp(key, "isActive") == 0)
    {
        lua_pushboolean(L, PhysicsConstraints[0]->isActive());
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

static int physics_newindex(lua_State *L)
{
    LuaPhysics *physicsUserdata = (LuaPhysics *)luaL_checkudata(L, 1, "SpinePhysics");

    if (!physicsUserdata)
    {
        return 0;
    }

    const char *key = luaL_checkstring(L, 2);

    Vector<PhysicsConstraint *> &PhysicsConstraints = physicsUserdata->constraints;

    // changes are applied to all constraints
    if (strcmp(key, "wind") == 0) 
    {
        float wind = luaL_checknumber(L, 3);
        for (int i = 0; i < PhysicsConstraints.size(); i++)
        {
            PhysicsConstraints[i]->setWind(wind);
        }
        return 0;
    } else if(strcmp(key, "inertia") == 0)
    {
        float inertia = luaL_checknumber(L, 3);
        for (int i = 0; i < PhysicsConstraints.size(); i++)
        {
            PhysicsConstraints[i]->setInertia(inertia);
        }
        return 0;
    } else if(strcmp(key, "strength") == 0)
    {
        float strength = luaL_checknumber(L, 3);
        for (int i = 0; i < PhysicsConstraints.size(); i++)
        {
            PhysicsConstraints[i]->setStrength(strength);
        }
        return 0;
    } else if(strcmp(key, "damping") == 0)
    {
        float damping = luaL_checknumber(L, 3);
        for (int i = 0; i < PhysicsConstraints.size(); i++)
        {
            PhysicsConstraints[i]->setDamping(damping);
        }
        return 0;
    } else if(strcmp(key, "massInverse") == 0)
    {
        float massInverse = luaL_checknumber(L, 3);
        for (int i = 0; i < PhysicsConstraints.size(); i++)
        {
            PhysicsConstraints[i]->setMassInverse(massInverse);
        }
        return 0;
    } else if(strcmp(key, "gravity") == 0)
    {
        float gravity = luaL_checknumber(L, 3);
        for (int i = 0; i < PhysicsConstraints.size(); i++)
        {
            PhysicsConstraints[i]->setGravity(gravity);
        }
        return 0;
    } else if(strcmp(key, "mix") == 0)
    {
        float mix = luaL_checknumber(L, 3);
        for (int i = 0; i < PhysicsConstraints.size(); i++)
        {
            PhysicsConstraints[i]->setMix(mix);
        }
        return 0;
    } else if(strcmp(key, "xVelocity") == 0)
    {
        float xVelocity = luaL_checknumber(L, 3);
        for (int i = 0; i < PhysicsConstraints.size(); i++)
        {
            PhysicsConstraints[i]->setXVelocity(xVelocity);
        }
        return 0;
    } else if(strcmp(key, "yVelocity") == 0)
    {
        float yVelocity = luaL_checknumber(L, 3);
        for (int i = 0; i < PhysicsConstraints.size(); i++)
        {
            PhysicsConstraints[i]->setYVelocity(yVelocity);
        }
        return 0;
    } else if(strcmp(key, "isActive") == 0)
    {
        bool active = lua_toboolean(L, 3);
        PhysicsConstraints[0]->setActive(active);
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

static int physics_gc(lua_State *L)
{
    LuaPhysics *physicsUserdata = (LuaPhysics *)luaL_checkudata(L, 1, "SpinePhysics");

    if (!physicsUserdata)
    {
        return 0;
    }

    physicsUserdata->~LuaPhysics();
    
    lua_pushnil(L);
    lua_setmetatable(L, 1);

    return 0;
}

void getPhysicsMt(lua_State *L)
{
    luaL_getmetatable(L, "SpinePhysics");
    if (lua_isnil(L, -1))
    {
        lua_pop(L, 1);
        luaL_newmetatable(L, "SpinePhysics");

        lua_pushstring(L, "__index");
        lua_pushcfunction(L, physics_index);
        lua_settable(L, -3);

        lua_pushstring(L, "__newindex");
        lua_pushcfunction(L, physics_newindex);
        lua_settable(L, -3);

        lua_pushstring(L, "translate");
        lua_pushcfunction(L, translate);
        lua_settable(L, -3);

        lua_pushstring(L, "rotate");
        lua_pushcfunction(L, rotate);
        lua_settable(L, -3);

        lua_pushcfunction(L, physics_gc);
        lua_setfield(L, -2, "__gc");
    }
}
