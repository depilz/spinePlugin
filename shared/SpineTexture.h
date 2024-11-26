#pragma once

#include "CoronaLua.h"
#include "LuaTableHolder.h"
#include <spine/TextureLoader.h>

#include <unordered_map>
#include <string>

struct Texture
{
    LuaTableHolder *texture;
    LuaTableHolder *textureTable;
};

struct TextureRef
{
    Texture texture;
    int refCount;
};

class SpineTextureLoader : public spine::TextureLoader
{
public:
    SpineTextureLoader(lua_State *L);

    void load(spine::AtlasPage &page, const spine::String &path) override;
    void unload(void *texture) override;

private:
    const char *resourcesDir;
    lua_State *L;
    std::unordered_map<std::string, TextureRef> textures;
    std::unordered_map<Texture*, std::string> textureToPath;
};
