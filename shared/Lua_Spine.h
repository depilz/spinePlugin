#pragma once

#include "CoronaLua.h"
#include "CoronaMacros.h"
#include <string>
#include <cassert>
#include "SpineCompat.h"
#include "LuaTableHolder.h"
#include "DataHolder.h"
#include "SkeletonDataHolder.h"
#include <spine/Extension.h>

using namespace spine;


static void loadGroupReferences(lua_State *L);

int loadAtlas(lua_State *L);
int loadSkeletonData(lua_State *L);
int create(lua_State *L);

// Solar2dExtension class extending DefaultSpineExtension
class Solar2dExtension : public DefaultSpineExtension
{
public:
    Solar2dExtension();
    virtual ~Solar2dExtension();
};

#ifdef _WIN32
extern "C"
{
    __declspec(dllexport) int SPINE_PLUGIN_LUAOPEN(lua_State *L);
}
#else
extern "C"
{
    int SPINE_PLUGIN_LUAOPEN(lua_State *L);
}
#endif

