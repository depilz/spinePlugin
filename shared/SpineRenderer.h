#include <cstddef>
#include "CoronaLua.h"
#include <string>
#include "LuaTableHolder.h"
#include "Lua_Skeleton.h"

void engine_drawMesh(lua_State *L, LuaTableHolder *newMesh, size_t numIndices, unsigned short *indices, float *positions, float *uvs);
void engine_updateMesh(lua_State *L, LuaTableHolder *meshHolder, size_t numIndices, unsigned short *indices, float *positions, float *uvs);
void engine_removeMesh(lua_State *L, LuaTableHolder *meshHolder);

void set_texture(lua_State *L, Texture *texture);
void set_blendMode(lua_State *L, spine::BlendMode blendMode);
void set_fill_color(lua_State *L, uint32_t *colors);
