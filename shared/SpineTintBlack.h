#pragma once

// Tint black (Spine's two-colour tint): a mesh whose render command carries a dark colour other than black is drawn
// with the reserved Solar2D effect filter.custom.plugin_spine_tintBlack, which adds the dark term of Spine's PMA
// formula. Header-only and included only by SpineRenderer.cpp, so the reduced headless builds never see it.

#include "CoronaLua.h"
#include "Lua_Skeleton.h"

// The reserved effect's full name, as assigned to mesh.fill.effect
static const char *const kTintBlackEffect = "filter.custom.plugin_spine_tintBlack";

// Registry key of the per-lua_State define result (true = defined, false = raised or unavailable). A string, not a
// static address, so plugin.spine42 and plugin.spine43 loaded in one Lua state share it and define the effect once.
static const char *const kTintBlackRegistryKey = "plugin_spine_tintBlack";

// Defines the effect and returns true, or returns false: silently when graphics.defineEffect is missing (headless
// mocks), with one warning when it raises. Its return value is no signal: Solar2D returns false after defining the
// effect (ShaderFactory::DefineEffect never sets its result) and false with an engine ERROR line when the name already
// exists, so an app that defined the reserved name first gets its own effect drawn.
// The dark rgb is the effect's vertexData r, g, b (straight, 0..1):
// rgb = tex.rgb * light.rgb + (tex.a - tex.rgb) * dark.rgb, on Solar2D's premultiplied texture.
static const char kTintBlackDefineChunk[] = R"lua(
local define = type(graphics) == "table" and graphics.defineEffect
if not define then return false end
local function param(name, index) return { name = name, index = index, default = 0, min = 0, max = 1 } end
local ok, err = pcall(define, {
  category = "filter", group = "custom", name = "plugin_spine_tintBlack",
  vertexData = { param("r", 0), param("g", 1), param("b", 2) },
  fragment = [[
P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, texCoord );
    P_COLOR vec4 result = CoronaColorScale( tex );
    P_COLOR float lightAlpha = CoronaColorScale( vec4( 1.0 ) ).a;
    result.rgb += ( tex.a - tex.rgb ) * CoronaVertexUserData.rgb * lightAlpha;
    return result;
}
]] })
if ok then return true end
print("WARNING: plugin.spine: could not define filter.custom.plugin_spine_tintBlack, tint black is off: " .. tostring(err))
return false
)lua";

// True when the tint-black effect is defined in this Lua state; the first call defines it, later calls read the result
static inline bool tintBlackDefined(lua_State *L)
{
    lua_getfield(L, LUA_REGISTRYINDEX, kTintBlackRegistryKey);
    if (!lua_isnil(L, -1))
    {
        bool defined = lua_toboolean(L, -1);
        lua_pop(L, 1);
        return defined;
    }
    lua_pop(L, 1);

    // protected: a raise here would longjmp out of renderCommands
    bool defined = luaL_loadstring(L, kTintBlackDefineChunk) == 0 && lua_pcall(L, 0, 1, 0) == 0 && lua_toboolean(L, -1);
    lua_pop(L, 1); // the chunk's result or the error

    lua_pushboolean(L, defined);
    lua_setfield(L, LUA_REGISTRYINDEX, kTintBlackRegistryKey);
    return defined;
}

// mesh.fill.effect = kTintBlackEffect, or nil when !on. Expects the mesh on top of the stack and leaves it there.
static inline void setTintBlackEffect(lua_State *L, bool on)
{
    lua_getfield(L, -1, "fill");
    if (on)
        lua_pushstring(L, kTintBlackEffect);
    else
        lua_pushnil(L);
    lua_setfield(L, -2, "effect");
    lua_pop(L, 1);
}

// mesh.fill.effect.r, g, b = the dark rgb (0x00rrggbb). Expects the mesh on top of the stack and leaves it there.
static inline void setTintBlackParams(lua_State *L, uint32_t rgb)
{
    lua_getfield(L, -1, "fill");
    lua_getfield(L, -1, "effect");
    lua_pushnumber(L, ((rgb >> 16) & 0xff) / 255.0f);
    lua_setfield(L, -2, "r");
    lua_pushnumber(L, ((rgb >> 8) & 0xff) / 255.0f);
    lua_setfield(L, -2, "g");
    lua_pushnumber(L, (rgb & 0xff) / 255.0f);
    lua_setfield(L, -2, "b");
    lua_pop(L, 2);
}

// Brings the mesh's tint-black effect (mesh on top of the stack) in line with its command's dark colour (AARRGGBB).
// The mesh carries the effect iff dark rgb != black, the effect is defined and the skeleton has no user effect (the
// user effect wins; onEffectUpdated forgets every mesh's tint when it replaces the effects, so tint never clears one).
// The effect is assigned only on transitions (every assignment makes a new Shader) and its params only on change.
// paintReplaced: set_texture gave the mesh a new Paint this draw, which dropped the effect.
static inline void updateTintBlack(lua_State *L, MeshData &meshData, uint32_t dark, bool userEffect, bool paintReplaced)
{
    if (paintReplaced)
        meshData.resetTint();

    uint32_t rgb = dark & 0x00ffffff;
    if (rgb == 0 || userEffect || !tintBlackDefined(L))
    {
        if (meshData.tintOn)
        {
            setTintBlackEffect(L, false);
            meshData.resetTint();
        }
        return;
    }

    if (!meshData.tintOn)
    {
        setTintBlackEffect(L, true);
        meshData.tintOn = true;
    }
    // a new effect starts at its defaults; rgb != 0 here, so the reset tintRgb (0) always differs and writes them
    if (meshData.tintRgb != rgb)
    {
        setTintBlackParams(L, rgb);
        meshData.tintRgb = rgb;
    }
}
