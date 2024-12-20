#include "LuaTableHolder.h"
#include "CoronaLua.h"

LuaTableHolder::LuaTableHolder()
    : L_(nullptr), ref_(LUA_NOREF)
{
}

LuaTableHolder::LuaTableHolder(lua_State *L)
    : L_(L), ref_(LUA_NOREF)
{
    saveReference();
}

LuaTableHolder::LuaTableHolder(lua_State *L, int index)
    : L_(L), ref_(LUA_NOREF)
{
    lua_pushvalue(L, index);
    saveReference();
}

LuaTableHolder::~LuaTableHolder()
{
    releaseTable();
}

// Move constructor
LuaTableHolder::LuaTableHolder(LuaTableHolder &&other) noexcept
    : L_(other.L_), ref_(other.ref_)
{
    other.L_ = nullptr;
    other.ref_ = LUA_NOREF;
}

// Move assignment operator
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

// Pushes the Lua table onto the stack; pushes nil if invalid
void LuaTableHolder::pushTable()
{
    if (isValid())
    {
        lua_rawgeti(L_, LUA_REGISTRYINDEX, ref_);
    }
    else
    {
        lua_pushnil(L_);
    }
}

// Checks if the Lua table reference is valid
bool LuaTableHolder::isValid() const
{
    return L_ != nullptr && ref_ != LUA_NOREF && ref_ != LUA_REFNIL;
}

// Initializes the Lua table if not already initialized
void LuaTableHolder::initialize(lua_State *L)
{
    if (!isValid())
    {
        L_ = L;
        saveReference();
    }
}

// Releases the Lua table reference
void LuaTableHolder::releaseTable()
{
    if (isValid())
    {
        luaL_unref(L_, LUA_REGISTRYINDEX, ref_);
        L_ = nullptr;
        ref_ = LUA_NOREF;
    }
}

// Saves the reference of the table stored at the top of the stack
void LuaTableHolder::saveReference()
{
    if (L_)
    {
        ref_ = luaL_ref(L_, LUA_REGISTRYINDEX);
        if (ref_ == LUA_REFNIL)
        {
            L_ = nullptr;
        }
    }
}
