#include <cstddef>
#include "CoronaLua.h"
#include <string>

// A single vertex with UV
struct Vertex {
   // Position in x/y plane
   float x, y;

   // UV coordinates
   float u, v;

   // Packed RGBA color
    unsigned int color;
};

// Define the Texture struct to hold a Lua reference
struct Texture
{
    std::string path;
};

#include "spine_skeleton.h"

// Draw the given mesh.
// - vertices is a pointer to an array of Vertex structures
// - indices is a pointer to an array of indices. Consecutive indices of 3 form a triangle.
// - numIndices the number of indices, must be divisible by 3, as there are 3 vertices in a triangle.
// - texture the texture to use
// - blendMode the blend mode to use
void engine_drawMesh(lua_State* L, float* positions, size_t numVertices, float* uvs, unsigned short* indices, size_t numIndices, Texture* texture, spine::BlendMode blendMode, uint32_t* colors);
void engine_updateMesh(lua_State *L, LuaTableHolder *meshHolder, float *positions, size_t numVertices, float *uvs, unsigned short *indices, size_t numIndices, Texture *texture, spine::BlendMode blendMode, uint32_t *colors);
void engine_removeMesh(lua_State *L, LuaTableHolder *meshHolder);
