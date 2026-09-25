// New implementation: effect userdata that fronts SpineSkeleton::effectData
#include "Lua_FillEffect.h"
#include "Lua_Skeleton.h"
#include "Lua_EffectData.h"
#include <vector>

static int effect_index(lua_State *L)
{
     LuaFillEffect *ud = (LuaFillEffect *)luaL_checkudata(L, 1, "SpineEffectData");
     const char *key = luaL_checkstring(L, 2);

     if (!ud || !ud->owner || !ud->owner->effectData)
     {
         return 0;
     }

     Lua_EffectData *e = ud->owner->effectData;
     if (strcmp(key, "name") == 0)
     {
         lua_pushstring(L, e->name().c_str());
         return 1;
     }

     const auto &attrs = e->attributes();
     auto it = attrs.find(key);
     if (it == attrs.end()) return 0;

     const auto &val = it->second;
     if (val.type == Lua_EffectData::AttributeValue::Type::Number)
     {
         lua_pushnumber(L, val.number);
         return 1;
     }
     // array
     lua_createtable(L, (int)val.array.size(), 0);
     for (size_t i = 0; i < val.array.size(); ++i)
     {
         lua_pushnumber(L, val.array[i]);
         lua_rawseti(L, -2, (int)i + 1);
     }
    return 1;
}

static int effect_newindex(lua_State *L)
{
    LuaFillEffect *ud = (LuaFillEffect *)luaL_checkudata(L, 1, "SpineEffectData");
    const char *key = luaL_checkstring(L, 2);

    if (!ud || !ud->owner)
    {
        return 0;
    }

     if (!ud->owner->effectData)
     {
         ud->owner->effectData = new Lua_EffectData();
     }
     Lua_EffectData *e = ud->owner->effectData;

     if (strcmp(key, "name") == 0)
     {
         const char *name = luaL_checkstring(L, 3);
         e->setName(name ? name : "");
         ud->owner->onEffectUpdated("name", L, 3);
         return 0;
     }

     if (lua_isnil(L, 3))
     {
         e->removeAttribute(key);
         ud->owner->onEffectUpdated(key, L, 3);
         return 0;
     }

     if (lua_isnumber(L, 3))
     {
         e->setAttribute(key, Lua_EffectData::AttributeValue::Number((float)lua_tonumber(L, 3)));
         ud->owner->onEffectUpdated(key, L, 3);
         return 0;
     }

     if (lua_istable(L, 3))
     {
         std::vector<float> arr;
         lua_Integer n = lua_objlen(L, 3);
         arr.reserve((size_t)n);
         for (lua_Integer i = 1; i <= n; ++i)
         {
             lua_rawgeti(L, 3, static_cast<int>(i));
             if (!lua_isnumber(L, -1))
             {
                 luaL_error(L, "Effect attribute array must contain only numbers (index %d)", (int)i);
             }
             arr.emplace_back((float)lua_tonumber(L, -1));
             lua_pop(L, 1);
         }
         e->setAttribute(key, Lua_EffectData::AttributeValue::Array(arr));
         ud->owner->onEffectUpdated(key, L, 3);
         return 0;
     }

     luaL_error(L, "Effect attribute '%s' must be a number, table of numbers, or nil", key);
    return 0;
}

static int effect_gc(lua_State *L)
{
    LuaFillEffect *ud = (LuaFillEffect *)luaL_checkudata(L, 1, "SpineEffectData");
    ud->~LuaFillEffect();
    return 0;
}

void getFillEffectMt(lua_State *L)
{
    if (luaL_newmetatable(L, "SpineEffectData"))
    {
        lua_pushcfunction(L, effect_index);
        lua_setfield(L, -2, "__index");

        lua_pushcfunction(L, effect_newindex);
        lua_setfield(L, -2, "__newindex");

        lua_pushcfunction(L, effect_gc);
        lua_setfield(L, -2, "__gc");
    }
}
