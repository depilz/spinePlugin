// PluginCore.h

#pragma once

#include <windows.h>
#include "lua.h"
#include "lauxlib.h"
#include "CoronaLua.h"
#include "CoronaMacros.h"

extern "C"
{
    CORONA_EXPORT int luaopen_plugin_spine(lua_State *L);
}
