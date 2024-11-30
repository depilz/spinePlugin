#pragma once

#include "CoronaLua.h"
#include "CoronaMacros.h"
#include <string>
#include <cassert>
#include <spine/spine.h>
#include "LuaTableHolder.h"
#include "DataHolder.h"
#include "SkeletonDataHolder.h"
#include "Extension.h"

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

extern "C"
{
    int luaopen_plugin_spine(lua_State *L);
}
