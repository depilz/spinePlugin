#include "SpineRenderer.h"
#include "CoronaGraphics.h"
#include "CoronaLua.h"
#include "CoronaMemory.h"

struct Vertex2
{
    float x;
    float y;
};

void engine_updateMesh(lua_State *L, LuaTableHolder *meshHolder, size_t numIndices, unsigned short *indices, float *positions, float *uvs)
{
    meshHolder->pushTable(L);
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
    lua_createtable(L, numIndices * 2, 0);
    for (size_t i = 0; i < numIndices; ++i)
    {
        if (positions[indices[i] * 2] < minX)
            minX = positions[indices[i] * 2];
        if (positions[indices[i] * 2] > maxX)
            maxX = positions[indices[i] * 2];
        if (positions[indices[i] * 2 + 1] < minY)
            minY = positions[indices[i] * 2 + 1];
        if (positions[indices[i] * 2 + 1] > maxY)
            maxY = positions[indices[i] * 2 + 1];
        lua_pushnumber(L, positions[indices[i] * 2]);
        lua_rawseti(L, -2, i * 2 + 1);
        lua_pushnumber(L, -positions[indices[i] * 2 + 1]);
        lua_rawseti(L, -2, i * 2 + 2);
    }
    lua_setfield(L, -2, "vertices");

    // create the uvs table
    lua_createtable(L, numIndices * 2, 0);
    for (size_t i = 0; i < numIndices; ++i)
    {
        lua_pushnumber(L, uvs[indices[i] * 2]);
        lua_rawseti(L, -2, i * 2 + 1);
        lua_pushnumber(L, uvs[indices[i] * 2 + 1]);
        lua_rawseti(L, -2, i * 2 + 2);
    }
    lua_setfield(L, -2, "uvs");

    lua_call(L, 2, 0);

    meshHolder->pushTable(L);

    lua_pushvalue(L, -1);

    lua_pushnumber(L, (minX + maxX) / 2);
    lua_setfield(L, -2, "x");

    lua_pushnumber(L, -(minY + maxY) / 2);
    lua_setfield(L, -2, "y");

    lua_pop(L, 1); // pop the mesh
}

void engine_drawMesh(lua_State *L, LuaTableHolder *newMesh, size_t numIndices, unsigned short *indices, float *positions, float *uvs)
{
    newMesh->pushTable(L);

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
    lua_createtable(L, numIndices * 2, 0);
    for (size_t i = 0; i < numIndices; ++i)
    {
        if (positions[indices[i] * 2] < minX)
            minX = positions[indices[i] * 2];
        if (positions[indices[i] * 2] > maxX)
            maxX = positions[indices[i] * 2];
        if (positions[indices[i] * 2 + 1] < minY)
            minY = positions[indices[i] * 2 + 1];
        if (positions[indices[i] * 2 + 1] > maxY)
            maxY = positions[indices[i] * 2 + 1];
        lua_pushnumber(L, positions[indices[i] * 2]);
        lua_rawseti(L, -2, i * 2 + 1);
        lua_pushnumber(L, -positions[indices[i] * 2 + 1]);
        lua_rawseti(L, -2, i * 2 + 2);
    }
    lua_setfield(L, -2, "vertices");

    // create the uvs table
    lua_createtable(L, numIndices * 2, 0);
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
        const char *error = lua_tostring(L, -1);
        printf("Lua Error: %s\n", error);
        lua_pop(L, 1); // Pop error message
        return;
    }

    int meshIndex = lua_gettop(L);
    lua_pushvalue(L, meshIndex);
}
void engine_removeMesh(lua_State *L, LuaTableHolder *meshHolder)
{
    meshHolder->pushTable(L);
    lua_getfield(L, -1, "removeSelf");
    meshHolder->pushTable(L);
    lua_call(L, 1, 0);
    lua_pop(L, 1);
}



void set_texture(lua_State *L, Texture *texture)
{
    // mesh.fill = { type "image", filename = "raptor.png"}
   LuaTableHolder *textureTable = ((Texture *)texture)->textureTable;
   textureTable->pushTable(L);
   lua_setfield(L, -2, "fill");
}

void set_blendMode(lua_State *L, BlendMode blendMode)
{
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
    lua_setfield(L, -2, "blendMode");
}

void set_fill_color(lua_State *L, uint32_t *colors)
{
    lua_getfield(L, -1, "setFillColor");
    lua_pushvalue(L, -2);

    uint32_t color = colors[0];
    float r = ((color >> 16) & 0xff) / 255.0f;
    float g = ((color >> 8) & 0xff) / 255.0f;
    float b = (color & 0xff) / 255.0f;
    float a = ((color >> 24) & 0xff) / 255.0f;

    lua_pushnumber(L, r);
    lua_pushnumber(L, g);
    lua_pushnumber(L, b);
    lua_pushnumber(L, a);

    lua_call(L, 5, 0); // Call mesh.setFillColor(mesh, r, g, b, a)
}
