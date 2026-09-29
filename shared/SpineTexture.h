#pragma once

#include "CoronaLua.h"
#include "LuaTableHolder.h"
#include <spine/TextureLoader.h>

#include <unordered_map>
#include <string>
#include "Texture.h"

struct TextureRef
{
    Texture *texture; // one heap Texture per path, shared by every page that uses it
    int refCount;
};

class SpineTextureLoader : public spine::TextureLoader
{
public:
    SpineTextureLoader(lua_State *L);

    void load(spine::AtlasPage &page, const spine::String &path) override;
    void unload(void *texture) override;

    // load() never raises (it runs inside new Atlas): the first failed texture path since clearFailure(), followed by
    // ": <error>" when graphics.newTexture raised, else empty.
    const std::string &failure() const { return failedPath; }
    void clearFailure() { failedPath.clear(); }

private:
    lua_State *L;
    std::unordered_map<std::string, TextureRef> textures;
    std::unordered_map<Texture*, std::string> textureToPath;
    std::string failedPath;
};
