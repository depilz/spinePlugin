// LuaTableHolder.h
#ifndef LUA_TABLE_HOLDER_H
#define LUA_TABLE_HOLDER_H

#include "CoronaLua.h" // Ensure this is the correct Lua header for your project
#include <string>

class LuaTableHolder
{
public:
    // Default constructor: Initializes without creating a Lua table
    LuaTableHolder()
        : L_(nullptr), ref_(LUA_NOREF)
    {
    }

    // Constructor that creates a new Lua table and stores a reference
    LuaTableHolder(lua_State *L)
        : L_(L), ref_(LUA_NOREF)
    {
        saveReference();
    }

    // Destructor: Releases the Lua table reference if valid
    ~LuaTableHolder()
    {
        releaseTable();
    }

    // Move constructor
    LuaTableHolder(LuaTableHolder &&other) noexcept
        : L_(other.L_), ref_(other.ref_)
    {
        other.L_ = nullptr;
        other.ref_ = LUA_NOREF;
    }

    // Move assignment operator
    LuaTableHolder &operator=(LuaTableHolder &&other) noexcept
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
    void pushTable() const
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
    bool isValid() const
    {
        return L_ != nullptr && ref_ != LUA_NOREF && ref_ != LUA_REFNIL;
    }

    // Initializes the Lua table if not already initialized
    void initialize(lua_State *L)
    {
        if (!isValid())
        {
            L_ = L;
            saveReference();
        }
    }

    // Releases the Lua table reference
    void releaseTable()
    {
        if (isValid())
        {
            luaL_unref(L_, LUA_REGISTRYINDEX, ref_);
            L_ = nullptr;
            ref_ = LUA_NOREF;
        }
    }

private:
    lua_State *L_;
    int ref_; // Reference to the Lua table in the registry

    // save the reference of the table stored at the top of the stack
    void saveReference()
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

    // Disable copy constructor and copy assignment
    LuaTableHolder(const LuaTableHolder &) = delete;
    LuaTableHolder &operator=(const LuaTableHolder &) = delete;
};

#endif // LUA_TABLE_HOLDER_H