#include "SpineRenderer.h"
#include "CoronaGraphics.h"
#include "CoronaLua.h"
#include "CoronaMemory.h"

struct Vertex2
{
    float x;
    float y;
};

// Helper function to create userdata with the required memory interface
void CreateBufferUserdata(lua_State *L, const void *buffer, size_t size)
{
    void *userdata = lua_newuserdata(L, size);
    memcpy(userdata, buffer, size);
    const char *metatableName = "BufferMeshMemoryMetatable";

    if (luaL_newmetatable(L, metatableName))
    {
        CoronaMemoryInterfaceInfo info = {};

        info.callbacks.getReadableBytes = [](CoronaMemoryWorkspace *ws)
        {
            return ws->vars[0].cp;
        };

        info.callbacks.getByteCount = [](CoronaMemoryWorkspace *ws)
        {
            return ws->vars[1].size;
        };

        info.getObject = [](lua_State *L, int arg, CoronaMemoryWorkspace *ws)
        {
            ws->vars[0].cp = (const char *)lua_touserdata(L, arg);
            ws->vars[1].size = lua_objlen(L, arg);

            return 1;
        };

        CoronaMemoryCreateInterface(L, &info);
        lua_setfield(L, -2, "__memory");
    }

    lua_setmetatable(L, -2);
}

void engine_updateMesh(lua_State *L, LuaTableHolder *meshHolder, float *positions, size_t numVertices, float *uvs, unsigned short *indices, size_t numIndices, Texture *texture, spine::BlendMode blendMode, uint32_t *colors)
{
    meshHolder->pushTable();       // meshTable
    lua_getfield(L, -1, "path");   // meshTable, path
    lua_getfield(L, -1, "update"); // meshTable, path, update

    lua_pushvalue(L, -2); // meshTable, path, update, path
    lua_remove(L, -3);    // meshTable, update, path
    lua_remove(L, -3);    // update, path

    lua_newtable(L);

    double minX = 99999999;
    double minY = 99999999;
    double maxX = -99999999;
    double maxY = -99999999;

    // Set up 'vertices' field
    {
        lua_pushstring(L, "vertices");
        lua_newtable(L);

        Vertex2 *vertices = new Vertex2[numIndices];
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

            vertices[i].x = positions[indices[i] * 2];
            vertices[i].y = -positions[indices[i] * 2 + 1];
        }

        lua_pushstring(L, "buffer");

        size_t verticesBufferSize = numIndices * sizeof(Vertex2);
        CreateBufferUserdata(L, vertices, verticesBufferSize); // "vertices", t, "buffer", userdata
        lua_settable(L, -3);

        delete[] vertices;

        lua_pushstring(L, "count");
        lua_pushinteger(L, numIndices);
        lua_settable(L, -3);

        lua_settable(L, -3);
    }

    // Set up 'uvs' field
    {
        lua_pushstring(L, "uvs");
        lua_newtable(L);

        Vertex2 *uvVertices = new Vertex2[numIndices];
        for (size_t i = 0; i < numIndices; ++i)
        {
            uvVertices[i].x = uvs[indices[i] * 2];
            uvVertices[i].y = uvs[indices[i] * 2 + 1];
        }

        lua_pushstring(L, "buffer");

        size_t uvsBufferSize = numIndices * sizeof(Vertex2);
        CreateBufferUserdata(L, uvVertices, uvsBufferSize);
        lua_settable(L, -3);

        delete[] uvVertices;

        lua_pushstring(L, "count");
        lua_pushinteger(L, numIndices);
        lua_settable(L, -3);

        lua_settable(L, -3);
    }

    lua_call(L, 2, 0); // Call update(path, { vertices = vertices, uvs = uvs })

    meshHolder->pushTable();

    lua_pushvalue(L, -1);

    lua_pushnumber(L, (minX + maxX) / 2);
    lua_setfield(L, -2, "x");

    lua_pushnumber(L, -(minY + maxY) / 2);
    lua_setfield(L, -2, "y");

    lua_pop(L, 1); // pop the mesh
}

void engine_drawMesh(lua_State *L, float *positions, size_t numVertices, float *uvs, unsigned short *indices, size_t numIndices, Texture *texture, spine::BlendMode blendMode, uint32_t *colors, LuaTableHolder *newMesh)
{
    newMesh->pushTable();

    // create the mesh parameters
    lua_createtable(L, 0, 3);

    // set the mode
    lua_pushstring(L, "triangles");
    lua_setfield(L, -2, "mode");

    // Set up 'vertices' field
    {
        lua_pushstring(L, "vertices");
        lua_createtable(L, 2, 0);

        Vertex2 *vertices = new Vertex2[numIndices];
        for (size_t i = 0; i < numIndices; ++i)
        {
            vertices[i].x = positions[indices[i] * 2];
            vertices[i].y = -positions[indices[i] * 2 + 1];
        }

        lua_pushstring(L, "buffer");

        size_t verticesBufferSize = numIndices * sizeof(Vertex2);
        CreateBufferUserdata(L, vertices, verticesBufferSize); // "vertices", t, "buffer", userdata
        lua_settable(L, -3);

        delete[] vertices;

        lua_pushstring(L, "count");
        lua_pushinteger(L, numIndices);
        lua_settable(L, -3);

        lua_settable(L, -3);
    }

    // Set up 'uvs' field
    {
        lua_pushstring(L, "uvs");
        lua_createtable(L, 2, 0);

        Vertex2 *uvVertices = new Vertex2[numIndices];
        for (size_t i = 0; i < numIndices; ++i)
        {
            uvVertices[i].x = uvs[indices[i] * 2];
            uvVertices[i].y = uvs[indices[i] * 2 + 1];
        }

        lua_pushstring(L, "buffer");

        size_t uvsBufferSize = numIndices * sizeof(Vertex2);
        CreateBufferUserdata(L, uvVertices, uvsBufferSize);
        lua_settable(L, -3);

        delete[] uvVertices;

        lua_pushstring(L, "count");
        lua_pushinteger(L, numIndices);
        lua_settable(L, -3);

        lua_settable(L, -3);
    }

    lua_call(L, 1, 1); // Call newMesh

    int meshIndex = lua_gettop(L);
    lua_pushvalue(L, meshIndex);

    // mesh.fill = { type "image", filename = "raptor.png"}
    LuaTableHolder *textureTable = ((Texture *)texture)->textureTable;
    textureTable->pushTable();
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

    lua_call(L, 5, 0);                            // Call mesh.setFillColor(mesh, r, g, b, a)

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
