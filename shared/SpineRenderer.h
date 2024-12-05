#include <cstddef>
#include "CoronaLua.h"
#include <string>
#include "LuaTableHolder.h"
#include "Lua_Skeleton.h"

void engine_drawMesh(lua_State *L, float *positions, size_t numVertices, float *uvs, unsigned short *indices, size_t numIndices, Texture *texture, spine::BlendMode blendMode, uint32_t *colors, LuaTableHolder *newMesh);
void engine_updateMesh(lua_State *L, LuaTableHolder *meshHolder, float *positions, size_t numVertices, float *uvs, unsigned short *indices, size_t numIndices, Texture *texture, spine::BlendMode blendMode, uint32_t *colors);
void engine_removeMesh(lua_State *L, LuaTableHolder *meshHolder);
