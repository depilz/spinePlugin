#include "spine_renderer.h"
#include "CoronaGraphics.h"
#include "BlendMode.h"

void engine_updateMesh(lua_State *L, LuaTableHolder *meshHolder, float *positions, size_t numVertices, float *uvs, unsigned short *indices, size_t numIndices, Texture *texture, spine::BlendMode blendMode, uint32_t *colors)
{
    // get the resources directory from the system using the Lua API
    lua_getglobal(L, "system");
    lua_getfield(L, -1, "pathForFile");
    lua_pushstring(L, "");
    lua_call(L, 1, 1); // Call 'system.getPathForFile("", system.ResourceDirectory)', expecting 1 result
    const char* resourcesDir = lua_tostring(L, -1);
    lua_pop(L, 1); // Pop the result
    lua_pop(L, 1); // Pop the system object

    
    // remove the resources directory from the Texture->path
    const char* texturePath = texture->path;
    const char* texturePathStart = strstr(texturePath, resourcesDir);
    if (texturePathStart != NULL)
    {
        texturePath = texturePathStart + strlen(resourcesDir);
    }

    meshHolder->pushTable();
    lua_getfield(L, -1, "path");
    lua_getfield(L, -1, "update");

    lua_pushvalue(L, -2); // push the mesh table
    lua_remove(L, -3); // remove the path table
    lua_remove(L, -3); // remove the mesh table

    // create the mesh parameters
    lua_newtable(L);

    // create the vertices table
    lua_newtable(L);
    for (size_t i = 0; i < numIndices; ++i)
    {
        lua_pushnumber(L, positions[indices[i] * 2]);
        lua_rawseti(L, -2, i * 2 + 1);
        lua_pushnumber(L, -positions[indices[i] * 2 + 1]);
        lua_rawseti(L, -2, i * 2 + 2);
    }
    lua_setfield(L, -2, "vertices");

    // create the uvs table
    lua_newtable(L);
    for (size_t i = 0; i < numIndices; ++i)
    {
        lua_pushnumber(L, uvs[indices[i] * 2]);
        lua_rawseti(L, -2, i * 2 + 1);
        lua_pushnumber(L, uvs[indices[i] * 2 + 1]);
        lua_rawseti(L, -2, i * 2 + 2);
    }
    lua_setfield(L, -2, "uvs");

    // create the indices table
    lua_newtable(L);
    for (size_t i = 0; i < numIndices; ++i)
    {
        lua_pushnumber(L, indices[i] + 1);
        lua_rawseti(L, -2, i + 1);
    }
    lua_setfield(L, -2, "indices");

    lua_call(L, 2, 0);






    // // lua_newtable(L);
    // // lua_pushstring(L, "type");
    // // lua_pushstring(L, "image");
    // // lua_settable(L, -3);
    // // lua_pushstring(L, "filename");
    // // lua_pushstring(L, texturePath);
    // // lua_settable(L, -3);
    // // lua_setfield(L, -2, "fill");

    // // set color with mesh.setFillColor
    // // meshHolder->pushTable();
    // // lua_getfield(L, -1, "setFillColor");         // Push mesh.setFillColor
    // // meshHolder->pushTable();
    // // lua_remove(L, -3);

    // // uint32_t color = colors[0];
    // // float r = ((color >> 16) & 0xff) / 255.0f;
    // // float g = ((color >> 8) & 0xff) / 255.0f;
    // // float b = (color & 0xff) / 255.0f;
    // // float a = ((color >> 24) & 0xff) / 255.0f;

    // // lua_pushnumber(L, r);                                // Push r
    // // lua_pushnumber(L, g);                                // Push g
    // // lua_pushnumber(L, b);                                // Push b
    // // lua_pushnumber(L, a);                                // Push a

    // // lua_call(L, 5, 0);                // Call setFillColor(self, r, g, b, a)
}

void engine_drawMesh(lua_State *L, float *positions, size_t numVertices, float *uvs, unsigned short *indices, size_t numIndices, Texture *texture, spine::BlendMode blendMode, uint32_t *colors)
{
    // get the resources directory from the system using the Lua API
    lua_getglobal(L, "system");
    lua_getfield(L, -1, "pathForFile");
    lua_pushstring(L, "");
    lua_call(L, 1, 1); // Call 'system.getPathForFile("", system.ResourceDirectory)', expecting 1 result
    const char* resourcesDir = lua_tostring(L, -1);
    lua_pop(L, 1); // Pop the result
    lua_pop(L, 1); // Pop the system object

    
    // remove the resources directory from the Texture->path
    const char* texturePath = texture->path;
    const char* texturePathStart = strstr(texturePath, resourcesDir);
    if (texturePathStart != NULL)
    {
        texturePath = texturePathStart + strlen(resourcesDir);
    }


    // first get the global display object
    lua_getglobal(L, "display");

    // get the newRect function from the display object
    lua_getfield(L, -1, "newMesh");

    // remove the display object from the stack
    lua_remove(L, -2);

    // create the mesh
    lua_pushnumber(L, 0); // x
    lua_pushnumber(L, 0); // y

    // create the mesh parameters
    lua_newtable(L);

    // set the mode
    lua_pushstring(L, "triangles");
    lua_setfield(L, -2, "mode");


    // create the vertices table
    // { x, y, x2, y2, x3, y3, ... }
    lua_newtable(L);
    for (size_t i = 0; i < numIndices; ++i)
    {
        lua_pushnumber(L, positions[indices[i] * 2]);
        lua_rawseti(L, -2, i * 2 + 1);
        lua_pushnumber(L, -positions[indices[i] * 2 + 1]);
        lua_rawseti(L, -2, i * 2 + 2);
    }
    lua_setfield(L, -2, "vertices");

    // create the uvs table
    lua_newtable(L);
    for (size_t i = 0; i < numIndices; ++i)
    {
        lua_pushnumber(L, uvs[indices[i] * 2]);
        lua_rawseti(L, -2, i * 2 + 1);
        lua_pushnumber(L, uvs[indices[i] * 2 + 1]);
        lua_rawseti(L, -2, i * 2 + 2);
    }
    lua_setfield(L, -2, "uvs");

    // create the indices table
    lua_newtable(L);
    for (size_t i = 0; i < numIndices; ++i)
    {
        lua_pushnumber(L, indices[i] + 1);
        lua_rawseti(L, -2, i + 1);
    }
    lua_setfield(L, -2, "indices");


    if (lua_pcall(L, 3, 1, 0) != 0) // Call 'newMesh' with 3 args, expecting 1 result
    {
        // Handle Lua error
        const char* error = lua_tostring(L, -1);
        printf("Lua Error: %s\n", error);
        lua_pop(L, 1); // Pop error message
        return;
    }

    // 'mesh' is now on top of the stack
    int meshIndex = lua_gettop(L);

    // **Step 5: Set 'mesh.x' and 'mesh.y' using 'mesh.path:getVertexOffset()'**
    lua_getfield(L, meshIndex, "path");                   // Push mesh.path
    lua_getfield(L, -1, "getVertexOffset");               // Push mesh.path.getVertexOffset

    lua_pushvalue(L, -2);                                 // Push mesh.path as 'self'
    lua_call(L, 1, 2);                                    // Call getVertexOffset(self), expecting 2 results

    // Assign returned x to mesh.x
    lua_pushvalue(L, meshIndex);                           // Push mesh
    lua_pushvalue(L, -2);                                  // Push x
    lua_setfield(L, -2, "x");                              // mesh.x = x

    // Assign returned y to mesh.y
    lua_pushvalue(L, meshIndex);                           // Push mesh
    lua_pushvalue(L, -1);                                  // Push y
    lua_setfield(L, -2, "y");                              // mesh.y = y

    // lua_pop(L, 3); // Pop y, x, and mesh.path.getVertexOffset

    // force texture { type "image", filename = "raptor.png"} on mesh.fill
    lua_newtable(L);
    lua_pushstring(L, "type");
    lua_pushstring(L, "image");
    lua_settable(L, -3);
    lua_pushstring(L, "filename");
    lua_pushstring(L, texturePath);
    lua_settable(L, -3);
    lua_setfield(L, meshIndex, "fill");


    // set color with mesh.setFillColor
    lua_getfield(L, meshIndex, "setFillColor");         // Push mesh.setFillColor
    lua_pushvalue(L, meshIndex);                         // Push mesh as 'self'

    uint32_t color = colors[0];
    float r = ((color >> 16) & 0xff) / 255.0f;
    float g = ((color >> 8) & 0xff) / 255.0f;
    float b = (color & 0xff) / 255.0f;
    float a = ((color >> 24) & 0xff) / 255.0f;

    lua_pushnumber(L, r);                                // Push r
    lua_pushnumber(L, g);                                // Push g
    lua_pushnumber(L, b);                                // Push b
    lua_pushnumber(L, a);                                // Push a

    if (lua_pcall(L, 5, 0, 0) != 0)                // Call setFillColor(self, r, g, b, a)
    {
        // Handle Lua error
        const char* error = lua_tostring(L, -1);
        printf("Lua Error: %s\n", error);
        lua_pop(L, 1); // Pop error message
        lua_pop(L, 1); // Pop mesh
        return;
    }

    // set the blend mode > mesh.blendMode "normal""add""multiply""sScreen"
    lua_pushstring(L, "blendMode");
    switch (blendMode)
    {
    case spine::BlendMode_Normal:
        lua_pushstring(L, "normal");
        break;
    case spine::BlendMode_Additive:
        lua_pushstring(L, "add");
        break;
    case spine::BlendMode_Multiply:
        lua_pushstring(L, "multiply");
        break;
    case spine::BlendMode_Screen:
        lua_pushstring(L, "screen");
        break;
    default:
        lua_pushstring(L, "normal");
        break;
    }
    lua_settable(L, -3);
}
