#include "CoronaLua.h"
#include "SpineTexture.h"
#include <string>
#include <spine/Atlas.h>

static LuaTableHolder *newTexture;

// Texture only gets unloaded when the Atlas is deleted
// and the Atlas IS NOT deleted along the skeleton, but by the garbage collector in Lua
// once there are no more references to it

SpineTextureLoader::SpineTextureLoader(lua_State *L) : L(L)
{
    lua_getglobal(L, "graphics");
    lua_getfield(L, -1, "newTexture");
    newTexture = new LuaTableHolder(L);
    lua_pop(L, 1);
}

void SpineTextureLoader::load(spine::AtlasPage &page, const spine::String &path)
{

    std::string shortPath = path.buffer();
    auto it = textures.find(shortPath);

    if (it != textures.end())
    {
        it->second.refCount++;
        page.texture = &it->second.texture;
    }
    else
    {
        newTexture->pushTable(L);

        lua_createtable(L, 0, 3);
        lua_pushstring(L, "image");
        lua_setfield(L, -2, "type");

        lua_pushstring(L, shortPath.c_str());
        lua_setfield(L, -2, "filename");

        lua_call(L, 1, 1);

        if (lua_isnil(L, -1))
        {
            luaL_error(L, "Failed to load texture: %s", shortPath.c_str());
            return;
        }

        LuaTableHolder *texture = new LuaTableHolder(L);
        texture->pushTable(L);

        lua_createtable(L, 0, 3);
        lua_pushstring(L, "image");
        lua_setfield(L, -2, "type");

        lua_getfield(L, -2, "filename");
        lua_setfield(L, -2, "filename");

        lua_getfield(L, -2, "baseDir");
        lua_setfield(L, -2, "baseDir");

        LuaTableHolder *textureTable = new LuaTableHolder(L);

        Texture *textureData = new Texture;
        textureData->texture = texture;
        textureData->textureTable = textureTable;
        lua_pop(L, 1);

        TextureRef textRef = {*textureData, 1};
        textures[shortPath] = textRef;
        textureToPath[textureData] = shortPath;

        page.texture = textureData;
    }
}

void SpineTextureLoader::unload(void *texture)
{
    auto it = textureToPath.find((Texture *)texture);
    if (it != textureToPath.end())
    {
        auto textRef = textures.find(it->second);
        if (textRef != textures.end())
        {
            textRef->second.refCount--;
            if (textRef->second.refCount == 0)
            {
                LuaTableHolder *textureHolder = textRef->second.texture.texture;
                textureHolder->pushTable(L);
                lua_getfield(L, -1, "releaseSelf");
                lua_pushvalue(L, -2);
                lua_call(L, 1, 0);
                lua_pop(L, 1);

                textureHolder->releaseTable();
                LuaTableHolder *textureTableHolder = textRef->second.texture.textureTable;
                textureTableHolder->releaseTable();

                delete textRef->second.texture.texture;
                delete textRef->second.texture.textureTable;
                textures.erase(textRef);
            }
        }
        textureToPath.erase(it);
    }
}
