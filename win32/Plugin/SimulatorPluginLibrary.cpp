#include "SimulatorPluginLibrary.h"
#include "CoronaLibrary.h"
#include "Lua_Spine.h"

extern "C"
{
    __declspec(dllexport) int luaopen_plugin_spine(lua_State *L);
}


CORONA_EXPORT int luaopen_plugin_spine(lua_State *L)
{
    return luaopen_spine(L);
}