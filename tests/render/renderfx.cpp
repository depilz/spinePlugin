// Scratch render fixture: stubs for the two Corona C APIs the plugin uses, plus inspection helpers.
// Linked together with ALL of the plugin's shared/*.cpp (incl. Lua_Spine, SpineRenderer, SpineTexture)
// so spine.loadAtlas/loadSkeletonData/create/draw run for real against a Lua mock of Solar2D.
#include "Lua_Skeleton.h"
#include "SpineRenderer.h"
#include "Texture.h"
#include "CoronaMemory.h"
#include <spine/SkeletonRenderer.h>
#include <vector>
#include <cstring>

#include <malloc/malloc.h>
#include <new>
#include <cstdlib>
static long g_liveNew = 0, g_liveNewBytes = 0, g_totalNew = 0;
static void *countedNew(size_t n) { void *p = std::malloc(n ? n : 1); if (!p) throw std::bad_alloc(); ++g_liveNew; ++g_totalNew; g_liveNewBytes += (long)malloc_size(p); return p; }
static void countedDelete(void *p) { if (!p) return; --g_liveNew; g_liveNewBytes -= (long)malloc_size(p); std::free(p); }
void *operator new(size_t n) { return countedNew(n); }
void *operator new[](size_t n) { return countedNew(n); }
void operator delete(void *p) noexcept { countedDelete(p); }
void operator delete[](void *p) noexcept { countedDelete(p); }
void operator delete(void *p, size_t) noexcept { countedDelete(p); }
void operator delete[](void *p, size_t) noexcept { countedDelete(p); }
static int newStats(lua_State *L) { lua_pushinteger(L, g_liveNew); lua_pushinteger(L, g_liveNewBytes); lua_pushinteger(L, g_totalNew); return 3; }

extern "C" lua_State *CoronaLuaGetCoronaThread(lua_State *L) { return L; }
extern "C" int CoronaMemoryCreateInterface(lua_State *L, const CoronaMemoryInterfaceInfo *) {
    lua_newtable(L); // stand-in for the memory proxy (only stored as __memory on the buffer metatable)
    return 1;
}

static SpineSkeleton *getSk(lua_State *L, int idx) {
    lua_pushstring(L, "_skeleton");
    lua_rawget(L, idx);
    SpineSkeleton *s = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    lua_pop(L, 1);
    return s;
}

static void pushCommandList(lua_State *L, RenderCommand *c) {
    lua_newtable(L);
    int i = 1;
    for (; c; c = c->next, ++i) {
        lua_createtable(L, 0, 6);
        lua_pushinteger(L, c->numIndices); lua_setfield(L, -2, "numIndices");
        lua_pushinteger(L, (int)c->blendMode); lua_setfield(L, -2, "blend");
        lua_pushnumber(L, (double)(c->colors ? c->colors[0] : 0)); lua_setfield(L, -2, "color");
        lua_pushnumber(L, (double)(c->darkColors ? c->darkColors[0] : 0)); lua_setfield(L, -2, "dark");
        lua_pushinteger(L, c->injectionSlotIndex); lua_setfield(L, -2, "injectionSlot");
        if (c->texture) {
            Texture *t = (Texture *)c->texture;
            t->textureTable->pushTable(L);
            lua_getfield(L, -1, "filename");
            lua_remove(L, -2);
        } else lua_pushnil(L);
        lua_setfield(L, -2, "tex");
        lua_rawseti(L, -2, i);
    }
}

// fx.expected(obj) -> mainCommands, splitCommands|nil  (what the vendored SkeletonRenderer produces right now)
static int expected(lua_State *L) {
    SpineSkeleton *s = getSk(L, 1);
    std::vector<int> inj;
    for (auto &i : s->injections) inj.push_back(i.getSlotIndex());
    SkeletonRenderer r;
    if (s->splitData.isSplitted()) {
        Vector<RenderCommand *> a, b;
        auto p = spc::renderSplit(r, *s->skeleton, inj, s->splitData.getSlotIndices(), a, b);
        pushCommandList(L, p.first);
        pushCommandList(L, p.second);
        return 2;
    }
    pushCommandList(L, r.render(*s->skeleton, inj));
    return 1;
}

static int boneWorld(lua_State *L) {
    SpineSkeleton *s = getSk(L, 1);
    Bone *b = s->skeleton->findBone(luaL_checkstring(L, 2));
    if (!b) return luaL_error(L, "no bone");
    lua_pushnumber(L, spc::applied(*b).getWorldX());
    lua_pushnumber(L, spc::applied(*b).getWorldY());
    return 2;
}

static int physicsInfo(lua_State *L) {
    SpineSkeleton *s = getSk(L, 1);
    auto &pcs = s->skeleton->getPhysicsConstraints();
    lua_newtable(L);
    for (size_t i = 0; i < pcs.size(); ++i) {
        lua_createtable(L, 0, 3);
        lua_pushstring(L, pcs[i]->getData().getName().buffer()); lua_setfield(L, -2, "name");
#if SPINE_43()
        Bone &bone = pcs[i]->getBone().getBone();
#else
        Bone &bone = *pcs[i]->getBone();
#endif
        lua_pushstring(L, bone.getData().getName().buffer()); lua_setfield(L, -2, "bone");
        lua_pushboolean(L, pcs[i]->isActive()); lua_setfield(L, -2, "active");
        lua_rawseti(L, -2, (int)i + 1);
    }
    lua_pushnumber(L, s->skeleton->getTime());
    return 2;
}

// fx.makePhysicsSkinRequired(obj, index1) : marks physics constraint data as skin-required (no skin has it) and updates cache.
static int makePhysicsSkinRequired(lua_State *L) {
    SpineSkeleton *s = getSk(L, 1);
    int i = (int)luaL_checkinteger(L, 2) - 1;
    auto &pcs = s->skeleton->getPhysicsConstraints();
    pcs[i]->getData().setSkinRequired(true);
    s->skeleton->updateCache();
    lua_pushboolean(L, pcs[i]->isActive());
    return 1;
}

template <class T> static ConstraintData *markSkinRequired(T *c) {
    if (!c) return NULL;
    c->getData().setSkinRequired(true);
    return &c->getData();
}

// fx.skinRequire(obj, "ik"|"physics", name[, skinName]) : marks the named constraint's data skin-required, adds it to
// skinName's constraints when given, and updates the cache.
static int skinRequire(lua_State *L) {
    Skeleton &sk = *getSk(L, 1)->skeleton;
    String name(luaL_checkstring(L, 3));
    PhysicsConstraint *pc = NULL;
    auto &pcs = sk.getPhysicsConstraints();
    for (size_t i = 0; i < pcs.size(); ++i)
        if (pcs[i]->getData().getName() == name) pc = pcs[i];
    ConstraintData *data = strcmp(luaL_checkstring(L, 2), "ik") == 0 ? markSkinRequired(spc::findIk(&sk, name))
                                                                       : markSkinRequired(pc);
    if (!data) return luaL_error(L, "no constraint");
    if (lua_isstring(L, 4)) spc::data(sk).findSkin(lua_tostring(L, 4))->getConstraints().add(data);
    sk.updateCache();
    return 0;
}

static int bufLen(lua_State *L) { lua_pushinteger(L, (lua_Integer)lua_objlen(L, 1)); return 1; }

static int meshCount(lua_State *L) {
    SpineSkeleton *s = getSk(L, 1);
    lua_pushinteger(L, (lua_Integer)s->meshes.count_valids());
    lua_pushinteger(L, (lua_Integer)s->meshes.size());
    return 2;
}

extern "C" int luaopen_renderfx(lua_State *L) {
    lua_newtable(L);
    const luaL_Reg fns[] = {{"expected", expected}, {"boneWorld", boneWorld}, {"physicsInfo", physicsInfo},
                            {"makePhysicsSkinRequired", makePhysicsSkinRequired}, {"skinRequire", skinRequire},
                            {"bufLen", bufLen},
                            {"meshCount", meshCount}, {"newStats", newStats}, {NULL, NULL}};
    luaL_register(L, NULL, fns);
    return 1;
}
