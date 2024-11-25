#pragma once

#include "CoronaLua.h"
#include "LuaTableHolder.h"
#include <spine/TextureLoader.h>

class SpineTextureLoader : public spine::TextureLoader
{
public:
    SpineTextureLoader(lua_State *L);

    void load(spine::AtlasPage &page, const spine::String &path) override;
    void unload(void *texture) override;

private:
    const char *resourcesDir;
    lua_State *L;
};