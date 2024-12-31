#include "LuaTableHolder.h"
#include "CoronaLua.h"
#include <cassert>

LuaTableHolder::LuaTableHolder()
    : L_(nullptr), ref_(LUA_NOREF)
{
}

LuaTableHolder::LuaTableHolder(lua_State *L)
    : L_(CoronaLuaGetCoronaThread(L)) // the *main* Lua state in Corona
      ,
      ref_(LUA_NOREF)
{
    // If the main state is not the same as L, move the top item over.
    if (L_ != L)
    {
        lua_xmove(L, L_, 1);
    }

    saveReference();
}

LuaTableHolder::LuaTableHolder(lua_State *L, int index)
    : L_(CoronaLuaGetCoronaThread(L))
      ,
      ref_(LUA_NOREF)
{
    lua_pushvalue(L, index);

    if (L_ != L)
    {
        lua_xmove(L, L_, 1);
    }

    saveReference();
}

LuaTableHolder::~LuaTableHolder()
{
    releaseTable();
}

LuaTableHolder::LuaTableHolder(LuaTableHolder &&other) noexcept
    : L_(other.L_), ref_(other.ref_)
{
    other.L_ = nullptr;
    other.ref_ = LUA_NOREF;
}

LuaTableHolder &LuaTableHolder::operator=(LuaTableHolder &&other) noexcept
{
    if (this != &other)
    {
        releaseTable();
        L_ = other.L_;
        ref_ = other.ref_;

        other.L_ = nullptr;
        other.ref_ = LUA_NOREF;
    }
    return *this;
}

void LuaTableHolder::pushTable(lua_State *L)
{
    if (isValid())
    {
        lua_rawgeti(L_, LUA_REGISTRYINDEX, ref_);
        lua_xmove(L_, L, 1);
    }
    else
    {
        lua_pushnil(L);
    }
}

bool LuaTableHolder::isValid() const
{
    return (L_ != nullptr) && (ref_ != LUA_NOREF) && (ref_ != LUA_REFNIL);
}

void LuaTableHolder::initialize(lua_State *L)
{
    if (!isValid())
    {
        L_ = CoronaLuaGetCoronaThread(L);

        if (L_ != L)
        {
            lua_xmove(L, L_, 1);
        }

        saveReference();
    }
}

void LuaTableHolder::releaseTable()
{
    if (isValid())
    {
        luaL_unref(L_, LUA_REGISTRYINDEX, ref_);
        L_ = nullptr;
        ref_ = LUA_NOREF;
    }
}

void LuaTableHolder::saveReference()
{
    if (L_)
    {
        ref_ = luaL_ref(L_, LUA_REGISTRYINDEX); // pops the value
        if (ref_ == LUA_REFNIL)
        {
            L_ = nullptr;
        }
    }
}
