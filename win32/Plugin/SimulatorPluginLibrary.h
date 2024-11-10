
#pragma once

#include "CoronaLua.h"
#include "CoronaMacros.h"

extern "C"
{
    CORONA_EXPORT int luaopen_plugin_spine(lua_State *L);
}
