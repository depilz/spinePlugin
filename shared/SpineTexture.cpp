#include "CoronaLua.h"
#include "SpineTexture.h"
#include <string>
#include <spine/Atlas.h>

static LuaTableHolder *newTexture;

static const char *ResourceDirectory = "ResourceDirectory";
static int resourcesRef = LUA_REFNIL;

// Texture only gets unloaded when the Atlas is deleted
// and the Atlas IS NOT deleted along the skeleton, but by the garbage collector in Lua
// once there are no more references to it

SpineTextureLoader::SpineTextureLoader(lua_State *L) : L(L)
{
    lua_getglobal(L, "system");
    lua_getfield(L, -1, "pathForFile");
    lua_pushstring(L, "");
    lua_getfield(L, -3, "ResourceDirectory");
    lua_pushvalue(L, -1);
    resourcesRef = luaL_ref(L, LUA_REGISTRYINDEX);
    lua_call(L, 2, 1);
    resourcesDir = strdup(lua_tostring(L, -1));

    lua_getglobal(L, "graphics");
    lua_getfield(L, -1, "newTexture");
    newTexture = new LuaTableHolder(L);
    lua_pop(L, 3);
}

void SpineTextureLoader::load(spine::AtlasPage &page, const spine::String &path)
{

    std::string absPath = path.buffer();
    auto it = textures.find(absPath);

    if (it != textures.end())
    {
        it->second.refCount++;
        page.texture = &it->second.texture;
    }
    else
    {
        std::string shortPath;
        if (absPath.find(resourcesDir) == 0)
        {
            shortPath = absPath.substr(strlen(resourcesDir));
        }
        else
        {
            shortPath = absPath;
        }

        newTexture->pushTable();

        lua_createtable(L, 0, 3);
        lua_pushstring(L, "image");
        lua_setfield(L, -2, "type");

        lua_pushstring(L, shortPath.c_str());
        lua_setfield(L, -2, "filename");

        lua_rawgeti(L, LUA_REGISTRYINDEX, resourcesRef);
        lua_setfield(L, -2, "baseDir");

        lua_call(L, 1, 1);

        if (lua_isnil(L, -1))
        {
            luaL_error(L, "Failed to load texture???: %s", shortPath.c_str());
        }

        LuaTableHolder *texture = new LuaTableHolder(L);
        texture->pushTable();

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
        lua_pop(L, 3);

        TextureRef textRef = {*textureData, 1};
        textures[absPath] = textRef;
        textureToPath[textureData] = absPath;

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
                textureHolder->pushTable();
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
