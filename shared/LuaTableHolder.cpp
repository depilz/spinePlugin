// LuaTableHolder.cpp
#include "LuaTableHolder.h"
#include <stdexcept>

// Constructor that creates a new Lua table and stores a reference
LuaTableHolder::LuaTableHolder(lua_State *L)
    : L_(L), ref_(LUA_NOREF)
{
    if (L_)
    {
        createTable();
    }
}

// Destructor: Releases the Lua table reference if valid
LuaTableHolder::~LuaTableHolder()
{
    releaseTable();
}

// Pushes the Lua table onto the stack; pushes nil if invalid
void LuaTableHolder::pushTable() const
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

// Retrieves the Lua state
lua_State *LuaTableHolder::getLuaState() const
{
    return L_;
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
        createTable();
    }
}

// Private method to create a new Lua table and store its reference
void LuaTableHolder::createTable()
{
    if (L_)
    {
        lua_newtable(L_);                       // Create a new table
        ref_ = luaL_ref(L_, LUA_REGISTRYINDEX); // Store reference
        if (ref_ == LUA_REFNIL)
        {
            throw std::runtime_error("Failed to create Lua table.");
        }
    }
}

// Private method to release the Lua table reference
void LuaTableHolder::releaseTable()
{
    if (isValid())
    {
        luaL_unref(L_, LUA_REGISTRYINDEX, ref_); // Release reference
        ref_ = LUA_NOREF;
        L_ = nullptr;
    }
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
        releaseTable(); // Release current reference
        L_ = other.L_;
        ref_ = other.ref_;
        other.L_ = nullptr;
        other.ref_ = LUA_NOREF;
    }
    return *this;
}