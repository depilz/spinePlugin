// split-oracle fixture (split and probe-batching suites): stubs for the Corona C APIs the plugin uses, plus inspection helpers. Linked with ALL of the
// checkout's shared/*.cpp + the line's runtime/spine-4.x/spine/*.cpp (so spine.create / draw / split / reassemble / inject run for real)
// against a Lua mock of Solar2D (mock.lua).
#include "Lua_Skeleton.h"
#include "SpineRenderer.h"
#include "Texture.h"
#include "CoronaMemory.h"
#include <spine/SkeletonRenderer.h>
#include <spine/RegionAttachment.h>
#include <spine/MeshAttachment.h>
#include <vector>
#include <cstring>
#include <cstdio>
#include <cstdarg>
#include <malloc/malloc.h>
#include <new>
#include <cstdlib>

// ---- operator new accounting (render-11 leak probe) ----
static long g_liveNew = 0, g_liveNewBytes = 0, g_totalNew = 0;
static void *countedNew(size_t n) { void *p = std::malloc(n ? n : 1); if (!p) throw std::bad_alloc(); ++g_liveNew; ++g_totalNew; g_liveNewBytes += (long)malloc_size(p); return p; }
static void countedDelete(void *p) { if (!p) return; --g_liveNew; g_liveNewBytes -= (long)malloc_size(p); std::free(p); }
#ifndef NO_COUNTED_NEW
void *operator new(size_t n) { return countedNew(n); }
void *operator new[](size_t n) { return countedNew(n); }
void operator delete(void *p) noexcept { countedDelete(p); }
void operator delete[](void *p) noexcept { countedDelete(p); }
void operator delete(void *p, size_t) noexcept { countedDelete(p); }
void operator delete[](void *p, size_t) noexcept { countedDelete(p); }
#endif
static int newStats(lua_State *L) { lua_pushinteger(L, g_liveNew); lua_pushinteger(L, g_liveNewBytes); lua_pushinteger(L, g_totalNew); return 3; }

// ---- Corona C API stubs ----
extern "C" lua_State *CoronaLuaGetCoronaThread(lua_State *L) { return L; }
extern "C" int CoronaMemoryCreateInterface(lua_State *L, const CoronaMemoryInterfaceInfo *) { lua_newtable(L); return 1; }
extern "C" void CoronaLuaWarning(lua_State *, const char *fmt, ...) {
    va_list ap; va_start(ap, fmt); std::fprintf(stdout, "WARNING: "); std::vfprintf(stdout, fmt, ap); std::fprintf(stdout, "\n"); va_end(ap);
}

typedef Vector<RenderCommand *> CmdList;

// render() in split mode returns a heap pair (1.5.0) or a pair by value (once render-11 is fixed)
static std::pair<RenderCommand *, RenderCommand *> unpair(std::pair<RenderCommand *, RenderCommand *> *p) { auto r = *p; delete p; return r; }
static std::pair<RenderCommand *, RenderCommand *> unpair(std::pair<RenderCommand *, RenderCommand *> p) { return p; }

// per-slot, unbatched reference (ref_renderer.cpp: a copy of the SAME tree's SkeletonRenderer with batching disabled)
struct RefCmd { int slot; int numIndices; int group; };
void refRender(Skeleton &sk, const std::vector<int> *splitSlots, std::vector<RefCmd> &out);

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
        lua_pushnumber(L, (double)(c->colors && c->numVertices ? c->colors[0] : 0)); lua_setfield(L, -2, "color");
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

// fx.isSplit(obj)
static int isSplit(lua_State *L) { lua_pushboolean(L, getSk(L, 1)->splitData.isSplitted()); return 1; }

// fx.expected(obj) -> mainCommands, splitCommands|nil  (what the tree's own SkeletonRenderer produces now)
static int expected(lua_State *L) {
    SpineSkeleton *s = getSk(L, 1);
    std::vector<int> inj;
    for (auto &i : s->injections) inj.push_back(i.getSlotIndex());
    SkeletonRenderer r;
    if (s->splitData.isSplitted()) {
        CmdList a, b;
        auto p = unpair(r.render(*s->skeleton, inj, s->splitData.getSlotIndices(), a, b));
        pushCommandList(L, p.first);
        pushCommandList(L, p.second);
        return 2;
    }
    pushCommandList(L, r.render(*s->skeleton, inj));
    return 1;
}

// fx.reference(obj) -> { {slot=0-based, name=, n=numIndices, group=1|2}, ... } in draw order (unbatched, same tree's runtime)
static int reference(lua_State *L) {
    SpineSkeleton *s = getSk(L, 1);
    std::vector<RefCmd> out;
    if (s->splitData.isSplitted()) refRender(*s->skeleton, &s->splitData.getSlotIndices(), out);
    else refRender(*s->skeleton, nullptr, out);
    lua_createtable(L, (int)out.size(), 0);
    for (size_t i = 0; i < out.size(); ++i) {
        lua_createtable(L, 0, 4);
        lua_pushinteger(L, out[i].slot); lua_setfield(L, -2, "slot");
        lua_pushstring(L, s->skeleton->getSlots()[out[i].slot]->getData().getName().buffer()); lua_setfield(L, -2, "name");
        lua_pushinteger(L, out[i].numIndices); lua_setfield(L, -2, "n");
        lua_pushinteger(L, out[i].group); lua_setfield(L, -2, "group");
        lua_rawseti(L, -2, (int)i + 1);
    }
    return 1;
}

// fx.slotIndex(obj, name) -> 0-based
static int slotIndex(lua_State *L) {
    SpineSkeleton *s = getSk(L, 1);
    Slot *slot = s->skeleton->findSlot(luaL_checkstring(L, 2));
    if (!slot) return luaL_error(L, "no slot %s", lua_tostring(L, 2));
    lua_pushinteger(L, slot->getData().getIndex());
    return 1;
}

static Attachment *currentAttachment(Slot *slot) {
    return spc::pose(*slot).getAttachment();
}

// fx.attachmentKind(obj, slotName) -> "region"|"mesh"|"clipping"|"other"|nil
static int attachmentKind(lua_State *L) {
    SpineSkeleton *s = getSk(L, 1);
    Slot *slot = s->skeleton->findSlot(luaL_checkstring(L, 2));
    if (!slot) return 0;
    Attachment *a = currentAttachment(slot);
    if (!a) return 0;
    if (a->getRTTI().isExactly(RegionAttachment::rtti)) lua_pushstring(L, "region");
    else if (a->getRTTI().isExactly(MeshAttachment::rtti)) lua_pushstring(L, "mesh");
    else lua_pushstring(L, "other");
    return 1;
}

// fx.setAttachmentAlpha(obj, slotName, a): sets the CURRENT region attachment's color alpha (1.2.5 has no Lua API for it)
static int setAttachmentAlpha(lua_State *L) {
    SpineSkeleton *s = getSk(L, 1);
    Slot *slot = s->skeleton->findSlot(luaL_checkstring(L, 2));
    if (!slot) return luaL_error(L, "no slot");
    Attachment *a = currentAttachment(slot);
    if (!a || !a->getRTTI().isExactly(RegionAttachment::rtti)) { lua_pushboolean(L, 0); return 1; }
    ((RegionAttachment *)a)->getColor().a = (float)luaL_checknumber(L, 3);
    lua_pushboolean(L, 1);
    return 1;
}

// fx.attachmentAlpha(obj, slotName) -> current region/mesh attachment color alpha (nil if none)
static int attachmentAlpha(lua_State *L) {
    SpineSkeleton *s = getSk(L, 1);
    Slot *slot = s->skeleton->findSlot(luaL_checkstring(L, 2));
    if (!slot) return 0;
    Attachment *a = currentAttachment(slot);
    if (!a) return 0;
    if (a->getRTTI().isExactly(RegionAttachment::rtti)) { lua_pushnumber(L, ((RegionAttachment *)a)->getColor().a); return 1; }
    if (a->getRTTI().isExactly(MeshAttachment::rtti)) { lua_pushnumber(L, ((MeshAttachment *)a)->getColor().a); return 1; }
    return 0;
}
static int meshCount(lua_State *L) {
    SpineSkeleton *s = getSk(L, 1);
    lua_pushinteger(L, (lua_Integer)s->meshes.count_valids());
    lua_pushinteger(L, (lua_Integer)s->meshes.size());
    return 2;
}

// fx.meshRefs(obj) -> array of the mesh tables the MeshManager currently references (valid ones)
static int meshRefs(lua_State *L) {
    SpineSkeleton *s = getSk(L, 1);
    lua_newtable(L);
    int i = 1;
    for (auto &m : s->meshes) {
        if (m.mesh.isValid()) { m.mesh.pushTable(L); lua_rawseti(L, -2, i++); }
    }
    return 1;
}

static int stackTop(lua_State *L) { lua_pushinteger(L, lua_gettop(L)); return 1; }

extern "C" int luaopen_splitfx(lua_State *L) {
    lua_newtable(L);
    const luaL_Reg fns[] = {{"expected", expected}, {"reference", reference}, {"isSplit", isSplit},
                            {"slotIndex", slotIndex}, {"attachmentKind", attachmentKind},
                            {"setAttachmentAlpha", setAttachmentAlpha}, {"meshCount", meshCount},
                            {"meshRefs", meshRefs}, {"attachmentAlpha", attachmentAlpha}, {"newStats", newStats}, {"stackTop", stackTop}, {NULL, NULL}};
    luaL_register(L, NULL, fns);
    return 1;
}
