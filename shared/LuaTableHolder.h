// LuaTableHolder.h
#ifndef LUA_TABLE_HOLDER_H
#define LUA_TABLE_HOLDER_H

#include "CoronaLua.h" // Ensure this is the correct Lua header for your project

class LuaTableHolder
{
public:
    LuaTableHolder();

    // Constructor that creates a new Lua table and stores a reference
    LuaTableHolder(lua_State *L);

    // Destructor: Releases the Lua table reference if valid
    ~LuaTableHolder();

    // Move constructor
    LuaTableHolder(LuaTableHolder &&other) noexcept;

    // Move assignment operator
    LuaTableHolder &operator=(LuaTableHolder &&other) noexcept;

    // Pushes the Lua table onto the stack; pushes nil if invalid
    void pushTable();

    // Checks if the Lua table reference is valid
    bool isValid() const;

    // Initializes the Lua table if not already initialized
    void initialize(lua_State *L);

    // Releases the Lua table reference
    void releaseTable();

private:
    lua_State *L_;
    int ref_; // Reference to the Lua table in the registry

    // Saves the reference of the table stored at the top of the stack
    void saveReference();

    // Disable copy constructor and copy assignment
    LuaTableHolder(const LuaTableHolder &) = delete;
    LuaTableHolder &operator=(const LuaTableHolder &) = delete;
};

#endif // LUA_TABLE_HOLDER_H