#include "SpineRenderer.h"
#include "CoronaGraphics.h"

void engine_updateMesh(lua_State *L, LuaTableHolder *meshHolder, float *positions, size_t numVertices, float *uvs, unsigned short *indices, size_t numIndices, LuaTableHolder *texture, spine::BlendMode blendMode, uint32_t *colors)
{
    meshHolder->pushTable();
    lua_getfield(L, -1, "path");
    lua_getfield(L, -1, "update");

    lua_pushvalue(L, -2);
    lua_remove(L, -3);
    lua_remove(L, -3);

    // create the mesh parameters
    lua_createtable(L, 0, 2);

    // create the vertices table
    double minX = 99999999;
    double minY = 99999999;
    double maxX = -99999999;
    double maxY = -99999999;
    lua_createtable(L, numVertices * 2, 0);
    for (size_t i = 0; i < numIndices; ++i)
    {
        if (positions[indices[i] * 2] < minX) minX = positions[indices[i] * 2];
        if (positions[indices[i] * 2] > maxX) maxX = positions[indices[i] * 2];
        if (positions[indices[i] * 2 + 1] < minY) minY = positions[indices[i] * 2 + 1];
        if (positions[indices[i] * 2 + 1] > maxY) maxY = positions[indices[i] * 2 + 1];
        lua_pushnumber(L, positions[indices[i] * 2]);
        lua_rawseti(L, -2, i * 2 + 1);
        lua_pushnumber(L, -positions[indices[i] * 2 + 1]);
        lua_rawseti(L, -2, i * 2 + 2);
    }
    lua_setfield(L, -2, "vertices");

    // create the uvs table
    lua_createtable(L, numVertices * 2, 0);
    for (size_t i = 0; i < numIndices; ++i)
    {
        lua_pushnumber(L, uvs[indices[i] * 2]);
        lua_rawseti(L, -2, i * 2 + 1);
        lua_pushnumber(L, uvs[indices[i] * 2 + 1]);
        lua_rawseti(L, -2, i * 2 + 2);
    }
    lua_setfield(L, -2, "uvs");

    lua_call(L, 2, 0);

    meshHolder->pushTable();

    lua_pushvalue(L, -1);

    lua_pushnumber(L, (minX + maxX) / 2);
    lua_setfield(L, -2, "x");

    lua_pushnumber(L, - (minY + maxY) / 2);
    lua_setfield(L, -2, "y");

    lua_pop(L, 1); // pop the mesh
}

void engine_drawMesh(lua_State *L, float *positions, size_t numVertices, float *uvs, unsigned short *indices, size_t numIndices, LuaTableHolder *texture, spine::BlendMode blendMode, uint32_t *colors, LuaTableHolder *newMesh)
{
    newMesh->pushTable();

    lua_pushnumber(L, 0); // x
    lua_pushnumber(L, 0); // y

    // create the mesh parameters
    lua_createtable(L, 0, 5);

    // set the mode
    lua_pushstring(L, "triangles");
    lua_setfield(L, -2, "mode");

    // create the vertices table
    // { x, y, x2, y2, x3, y3, ... }
    double minX = 99999999;
    double minY = 99999999;
    double maxX = -99999999;
    double maxY = -99999999;
    lua_createtable(L, numVertices * 2, 0);
    for (size_t i = 0; i < numIndices; ++i)
    {
        if (positions[indices[i] * 2] < minX) minX = positions[indices[i] * 2];
        if (positions[indices[i] * 2] > maxX) maxX = positions[indices[i] * 2];
        if (positions[indices[i] * 2 + 1] < minY) minY = positions[indices[i] * 2 + 1];
        if (positions[indices[i] * 2 + 1] > maxY) maxY = positions[indices[i] * 2 + 1];
        lua_pushnumber(L, positions[indices[i] * 2]);
        lua_rawseti(L, -2, i * 2 + 1);
        lua_pushnumber(L, -positions[indices[i] * 2 + 1]);
        lua_rawseti(L, -2, i * 2 + 2);
    }
    lua_setfield(L, -2, "vertices");

    // create the uvs table
    lua_createtable(L, numVertices * 2, 0);
    for (size_t i = 0; i < numIndices; ++i)
    {
        lua_pushnumber(L, uvs[indices[i] * 2]);
        lua_rawseti(L, -2, i * 2 + 1);
        lua_pushnumber(L, uvs[indices[i] * 2 + 1]);
        lua_rawseti(L, -2, i * 2 + 2);
    }
    lua_setfield(L, -2, "uvs");

    lua_pushnumber(L, (minX + maxX) / 2);
    lua_setfield(L, -2, "x");

    lua_pushnumber(L, -(minY + maxY) / 2);
    lua_setfield(L, -2, "y");

    if (lua_pcall(L, 3, 1, 0) != 0) // Call display.newMesh(x, y, { vertices = vertices, uvs = uvs })
    {
        // Handle Lua error
        const char* error = lua_tostring(L, -1);
        printf("Lua Error: %s\n", error);
        lua_pop(L, 1); // Pop error message
        return;
    }

    int meshIndex = lua_gettop(L);
    lua_pushvalue(L, meshIndex);

    // mesh.fill = { type "image", filename = "raptor.png"}
    texture->pushTable();
    lua_setfield(L, meshIndex, "fill");

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

void engine_removeMesh(lua_State *L, LuaTableHolder *meshHolder)
{
    meshHolder->pushTable();
    lua_getfield(L, -1, "removeSelf");
    meshHolder->pushTable();
    lua_call(L, 1, 0);
    lua_pop(L, 1);
}
