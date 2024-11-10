#include "SimulatorPluginLibrary.h"
#include "CoronaLua.h"
#include "CoronaLibrary.h"
#include "spine_skeleton.h"

// Define the version as a constant
#define VERSION "1.0.0"

extern "C"
{
    __declspec(dllexport) int luaopen_plugin_spine(lua_State *L);
}

// Register the functions with Lua
static const luaL_Reg pluginFunctions[] = 
{
    {"create", create},

    {NULL, NULL}};

// Define the luaopen function using CoronaLibrary
CORONA_EXPORT int luaopen_plugin_spine(lua_State *L)
{
    const char kName[] = "plugin.spine";
    const char kVersion[] = "0.0.1";

    // Create a new Corona library
    lua_newtable(L);

    // Register the functions into the library
    luaL_register(L, NULL, pluginFunctions);

    return 1; // Return the library
}