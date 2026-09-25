#pragma once

#include "CoronaLua.h"

class LuaTableHolder
{
public:
    LuaTableHolder();

    LuaTableHolder(lua_State *L);
    LuaTableHolder(lua_State *L, int index);

    LuaTableHolder(LuaTableHolder &&other) noexcept;
    LuaTableHolder &operator=(LuaTableHolder &&other) noexcept;

    ~LuaTableHolder();

    void pushTable(lua_State *L);
    bool isValid() const;
    void initialize(lua_State *L);
    void releaseTable();

private:
    lua_State *L_;
    int ref_;

    void saveReference();

    // Disable copy constructor and copy assignment
    LuaTableHolder(const LuaTableHolder &) = delete;
    LuaTableHolder &operator=(const LuaTableHolder &) = delete;
};
