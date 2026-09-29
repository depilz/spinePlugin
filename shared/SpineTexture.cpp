#include "CoronaLua.h"
#include "SpineTexture.h"
#include <string>
#include <spine/Atlas.h>

static LuaTableHolder *newTexture;

// Texture only gets unloaded when the Atlas is deleted
// and the Atlas IS NOT deleted along the skeleton, but by the garbage collector in Lua
// once there are no more references to it

SpineTextureLoader::SpineTextureLoader(lua_State *L) : L(CoronaLuaGetCoronaThread(L)) // never keep a coroutine
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
        page.texture = it->second.texture;
    }
    else
    {
        newTexture->pushTable(L);

        lua_createtable(L, 0, 3);
        lua_pushstring(L, "image");
        lua_setfield(L, -2, "type");

        lua_pushstring(L, shortPath.c_str());
        lua_setfield(L, -2, "filename");

        // Record the failure and leave page.texture null: a raise here would longjmp out of new Atlas and leak it.
        int status = lua_pcall(L, 1, 1, 0);
        if (status != 0 || lua_isnil(L, -1))
        {
            if (failedPath.empty())
            {
                failedPath = shortPath;
                if (status != 0 && lua_isstring(L, -1)) failedPath.append(": ").append(lua_tostring(L, -1));
            }
            lua_pop(L, 1);
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

        TextureRef textRef = {textureData, 1};
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
                LuaTableHolder *textureHolder = textRef->second.texture->texture;
                textureHolder->pushTable(L);
                lua_getfield(L, -1, "releaseSelf");
                lua_pushvalue(L, -2);
                lua_call(L, 1, 0);
                lua_pop(L, 1);

                textureHolder->releaseTable();
                LuaTableHolder *textureTableHolder = textRef->second.texture->textureTable;
                textureTableHolder->releaseTable();

                delete textRef->second.texture->texture;
                delete textRef->second.texture->textureTable;
                delete textRef->second.texture;
                textures.erase(textRef);
                textureToPath.erase(it);
            }
        }
    }
}
