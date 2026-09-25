// skins_probe: read-only introspection of native state that the
// Lua API does not expose (refcounts, pointers, owner flags, sequence index).
#include "Lua_Skeleton.h"
#include "Lua_Slot.h"
#include "Lua_Skin.h"
#include "Lua_Attachment.h"
#include <cstdio>

static SpineSkeleton *skel(lua_State *L, int idx) {
    lua_getfield(L, idx, "_skeleton");
    auto *v = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    lua_pop(L, 1);
    return v;
}
static void pushPtr(lua_State *L, const void *p) {
    if (!p) { lua_pushnil(L); return; }
    char buf[32]; std::snprintf(buf, sizeof buf, "%p", p); lua_pushstring(L, buf);
}
static Attachment *att(lua_State *L, int idx) {
    return ((LuaAttachment *)luaL_checkudata(L, idx, "SpineAttachment"))->attachment;
}

// refCount(attachmentWrapper) -> native refcount (includes the wrapper's own reference)
static int refCount(lua_State *L) { lua_pushinteger(L, att(L, 1)->getRefCount()); return 1; }
// ptr(attachmentWrapper|skinWrapper) -> "%p"
static int ptr(lua_State *L) {
    if (luaL_checkudata(L, 1, "SpineAttachment")) {}
    pushPtr(L, att(L, 1)); return 1;
}
static int skinPtr(lua_State *L) { pushPtr(L, ((LuaSkin *)luaL_checkudata(L, 1, "SpineSkin"))->skin); return 1; }
// skinOwner(skinWrapper) -> ownsMemory, shared owners (excluding this probe's temp)
static int skinOwner(lua_State *L) {
    auto *s = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");
    lua_pushboolean(L, s->owner->ownsMemory);
    lua_pushinteger(L, (lua_Integer)s->owner.use_count());
    return 2;
}
// ownerFor(obj) -> ownsMemory,use_count of the owner registered for the skeleton's current skin (nil if none)
static int appliedOwner(lua_State *L) {
    auto *v = skel(L, 1);
    if (!v->appliedSkinOwner) { lua_pushnil(L); return 1; }
    lua_pushboolean(L, v->appliedSkinOwner->ownsMemory);
    lua_pushinteger(L, (lua_Integer)v->appliedSkinOwner.use_count());
    pushPtr(L, v->appliedSkinOwner->skin);
    return 3;
}
static int skeletonSkinPtr(lua_State *L) { pushPtr(L, skel(L, 1)->skeleton->getSkin()); return 1; }
static Slot *slotOf(lua_State *L) {
    auto *v = skel(L, 1);
    Slot *s = v->skeleton->findSlot(luaL_checkstring(L, 2));
    if (!s) luaL_error(L, "no slot %s", lua_tostring(L, 2));
    return s;
}
static int sequenceIndex(lua_State *L) { lua_pushinteger(L, slotOf(L)->getSequenceIndex()); return 1; }
static int deformSize(lua_State *L) { lua_pushinteger(L, (lua_Integer)slotOf(L)->getDeform().size()); return 1; }
static int slotAttachmentPtr(lua_State *L) { pushPtr(L, slotOf(L)->getAttachment()); return 1; }
static int slotAttachmentRef(lua_State *L) {
    Attachment *a = slotOf(L)->getAttachment();
    if (!a) { lua_pushnil(L); return 1; }
    lua_pushinteger(L, a->getRefCount()); return 1;
}
// parentInfo(attachmentWrapper) -> parentPtr, parentRefCount, timelinePtr, timelineRefCount, hasSequence
static int meshInfo(lua_State *L) {
    Attachment *a = att(L, 1);
    int n = 0;
    if (a->getRTTI().instanceOf(MeshAttachment::rtti)) {
        auto *m = (MeshAttachment *)a;
        pushPtr(L, m->getParentMesh()); lua_pushinteger(L, m->getParentMesh() ? m->getParentMesh()->getRefCount() : 0);
        n += 2;
    } else { lua_pushnil(L); lua_pushnil(L); n += 2; }
    if (a->getRTTI().instanceOf(VertexAttachment::rtti)) {
        auto *v = (VertexAttachment *)a;
        pushPtr(L, v->getTimelineAttachment()); lua_pushinteger(L, v->getTimelineAttachment()->getRefCount());
    } else { lua_pushnil(L); lua_pushnil(L); }
    n += 2;
    bool seq = false;
    if (a->getRTTI().instanceOf(RegionAttachment::rtti)) seq = ((RegionAttachment *)a)->getSequence() != nullptr;
    if (a->getRTTI().instanceOf(MeshAttachment::rtti)) seq = ((MeshAttachment *)a)->getSequence() != nullptr;
    lua_pushboolean(L, seq); n++;
    return n;
}
static int dataSkinCount(lua_State *L) { lua_pushinteger(L, (lua_Integer)skel(L, 1)->skeletonData->getSkins().size()); return 1; }
static int slotColor(lua_State *L) {
    Slot *s = slotOf(L);
    lua_pushnumber(L, s->getColor().r); lua_pushnumber(L, s->getSolarColor().r); return 2;
}
static int drawOrderFirst(lua_State *L) {
    auto *v = skel(L, 1);
    lua_pushstring(L, v->skeleton->getDrawOrder()[0]->getData().getName().buffer()); return 1;
}
// ownerProbe(skinWrapper, ownsMemory) -> calls getLuaSkinOwner(skin, flag) and reports what it returned
static int ownerProbe(lua_State *L) {
    Skin *skin = ((LuaSkin *)luaL_checkudata(L, 1, "SpineSkin"))->skin;
    auto o = getLuaSkinOwner(skin, lua_toboolean(L, 2));
    lua_pushboolean(L, o->ownsMemory);
    return 1;
}

extern "C" int luaopen_skins_probe(lua_State *L) {
    lua_newtable(L);
    const luaL_Reg fns[] = {
        {"refCount", refCount}, {"ptr", ptr}, {"skinPtr", skinPtr}, {"skinOwner", skinOwner},
        {"appliedOwner", appliedOwner}, {"skeletonSkinPtr", skeletonSkinPtr},
        {"sequenceIndex", sequenceIndex}, {"deformSize", deformSize}, {"slotAttachmentPtr", slotAttachmentPtr},
        {"slotAttachmentRef", slotAttachmentRef}, {"meshInfo", meshInfo}, {"dataSkinCount", dataSkinCount},
        {"slotColor", slotColor}, {"drawOrderFirst", drawOrderFirst}, {"ownerProbe", ownerProbe}, {NULL, NULL}};
    luaL_register(L, NULL, fns);
    return 1;
}
