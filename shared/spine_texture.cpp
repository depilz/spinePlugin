#include "spine_texture.h"
#include <string>
#include <spine/Atlas.h>

SpineTextureLoader::SpineTextureLoader(lua_State *L) : L(L)
{
    lua_getglobal(L, "system");
    lua_getfield(L, -1, "pathForFile");
    lua_pushstring(L, "");
    lua_call(L, 1, 1);
    resourcesDir = lua_tostring(L, -1);
    lua_pop(L, 2);
}

void SpineTextureLoader::load(spine::AtlasPage &page, const spine::String &path)
{
    // remove the resources directory from the Texture->path
    std::string texturePath = path.buffer();
    const char* texturePathStart = strstr(texturePath.c_str(), resourcesDir);
    if (texturePathStart != NULL)
    {
        texturePath = texturePathStart + strlen(resourcesDir);
    }

    lua_createtable(L, 0, 2);
    lua_pushstring(L, "image");
    lua_setfield(L, -2, "type");

    lua_pushstring(L, texturePath.c_str());
    lua_setfield(L, -2, "filename");

    LuaTableHolder *texture = new LuaTableHolder(L, -1); // Assuming LuaTableHolder(L, index)
    lua_pop(L, 1);

    page.texture = static_cast<void *>(texture);
}

void SpineTextureLoader::unload(void *texture)
{
    LuaTableHolder *luaTexture = static_cast<LuaTableHolder *>(texture);
    delete luaTexture;
}
