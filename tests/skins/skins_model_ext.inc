
// ---- skins-model introspection, included by skins_fixture.cpp ----
#include "Lua_Skin.h"
#include <string>
static SpineSkeleton *objSkel(lua_State *L, int idx) {
    lua_getfield(L, idx, "_skeleton");
    auto *v = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    lua_pop(L, 1);
    return v;
}
static void pushPtr(lua_State *L, const void *p) { char b[32]; snprintf(b, sizeof b, "%p", p); lua_pushstring(L, b); }
static void pushAttachmentInfo(lua_State *L, Attachment *a) {
    if (!a) { lua_pushboolean(L, 0); return; }
    lua_newtable(L);
    lua_pushstring(L, a->getName().buffer()); lua_setfield(L, -2, "name");
    pushPtr(L, a); lua_setfield(L, -2, "ptr");
    lua_pushinteger(L, a->getRefCount()); lua_setfield(L, -2, "refCount");
    lua_pushstring(L, a->getRTTI().getClassName()); lua_setfield(L, -2, "type");
    if (a->getRTTI().instanceOf(VertexAttachment::rtti)) {
        auto *va = (VertexAttachment *)a;
        Attachment *t = va->getTimelineAttachment();
        pushPtr(L, t); lua_setfield(L, -2, "timelinePtr");
        if (t) { lua_pushstring(L, t->getName().buffer()); lua_setfield(L, -2, "timelineName"); }
    }
    if (a->getRTTI().isExactly(MeshAttachment::rtti)) {
        auto *m = (MeshAttachment *)a;
        if (m->getParentMesh()) { pushPtr(L, m->getParentMesh()); lua_setfield(L, -2, "parentPtr");
            lua_pushstring(L, m->getParentMesh()->getName().buffer()); lua_setfield(L, -2, "parentName"); }
    }
}
// fx.slotInfo(obj, slotName) -> {attachment=info|false, deformSize, boneActive}
static int slotInfo(lua_State *L) {
    SpineSkeleton *v = objSkel(L, 1);
    Slot *slot = v->skeleton->findSlot(luaL_checkstring(L, 2));
    if (!slot) return luaL_error(L, "no slot");
    lua_newtable(L);
    pushAttachmentInfo(L, slot->getAttachment()); lua_setfield(L, -2, "attachment");
    lua_pushinteger(L, (lua_Integer)slot->getDeform().size()); lua_setfield(L, -2, "deformSize");
    lua_pushboolean(L, slot->getBone().isActive()); lua_setfield(L, -2, "boneActive");
    lua_pushinteger(L, slot->getSequenceIndex()); lua_setfield(L, -2, "sequenceIndex");
    return 1;
}
// fx.dataSkinEntry(obj, skinName, slotName, placeholder) -> info|false  (skin from SkeletonData, "" = default)
static int dataSkinEntry(lua_State *L) {
    SpineSkeleton *v = objSkel(L, 1);
    const char *skinName = luaL_checkstring(L, 2);
    Skin *skin = skinName[0] ? v->skeletonData->findSkin(skinName) : v->skeletonData->getDefaultSkin();
    if (!skin) return luaL_error(L, "no skin %s", skinName);
    SlotData *sd = v->skeletonData->findSlot(luaL_checkstring(L, 3));
    if (!sd) return luaL_error(L, "no slot");
    pushAttachmentInfo(L, skin->getAttachment(sd->getIndex(), luaL_checkstring(L, 4)));
    return 1;
}
// fx.luaSkinEntry(skinUD, obj, slotName, placeholder) -> info|false
static int luaSkinEntry(lua_State *L) {
    LuaSkin *ls = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");
    SpineSkeleton *v = objSkel(L, 2);
    SlotData *sd = v->skeletonData->findSlot(luaL_checkstring(L, 3));
    if (!sd) return luaL_error(L, "no slot");
    pushAttachmentInfo(L, ls->skin->getAttachment(sd->getIndex(), luaL_checkstring(L, 4)));
    return 1;
}
// fx.setSkinRaw(obj, name|nil): Skeleton::setSkin only (no setSlotsToSetupPose, no forced updateCache)
static int setSkinRaw(lua_State *L) {
    SpineSkeleton *v = objSkel(L, 1);
    if (lua_isnoneornil(L, 2)) v->skeleton->setSkin((Skin *)NULL);
    else if (lua_isstring(L, 2)) v->skeleton->setSkin(String(lua_tostring(L, 2)));
    else { LuaSkin *ls = (LuaSkin *)luaL_checkudata(L, 2, "SpineSkin"); v->skeleton->setSkin(ls->skin); }
    return 0;
}
static int skinName(lua_State *L) {
    SpineSkeleton *v = objSkel(L, 1);
    Skin *s = v->skeleton->getSkin();
    if (s) lua_pushstring(L, s->getName().buffer()); else lua_pushnil(L);
    return 1;
}
static int updateCacheFn(lua_State *L) { objSkel(L, 1)->skeleton->updateCache(); return 0; }
// fx.activeConstraints(obj) -> { "ik:name"=bool, "transform:name"=bool, "path:..", "physics:.." }
static int activeConstraints(lua_State *L) {
    Skeleton *sk = objSkel(L, 1)->skeleton;
    lua_newtable(L);
    for (size_t i = 0; i < sk->getIkConstraints().size(); i++) { auto *c = sk->getIkConstraints()[i];
        lua_pushboolean(L, c->isActive()); lua_setfield(L, -2, (std::string("ik:") + c->getData().getName().buffer()).c_str()); }
    for (size_t i = 0; i < sk->getTransformConstraints().size(); i++) { auto *c = sk->getTransformConstraints()[i];
        lua_pushboolean(L, c->isActive()); lua_setfield(L, -2, (std::string("transform:") + c->getData().getName().buffer()).c_str()); }
    for (size_t i = 0; i < sk->getPathConstraints().size(); i++) { auto *c = sk->getPathConstraints()[i];
        lua_pushboolean(L, c->isActive()); lua_setfield(L, -2, (std::string("path:") + c->getData().getName().buffer()).c_str()); }
    for (size_t i = 0; i < sk->getPhysicsConstraints().size(); i++) { auto *c = sk->getPhysicsConstraints()[i];
        lua_pushboolean(L, c->isActive()); lua_setfield(L, -2, (std::string("physics:") + c->getData().getName().buffer()).c_str()); }
    return 1;
}
static int updateCacheCount(lua_State *L) { lua_pushinteger(L, (lua_Integer)objSkel(L, 1)->skeleton->getUpdateCacheList().size()); return 1; }
// fx.cppSkinScenario(obj, which): raw spine-cpp ownership scenarios (no Lua bindings involved)
static int cppSkinScenario(lua_State *L) {
    SpineSkeleton *v = objSkel(L, 1);
    const char *which = luaL_checkstring(L, 2);
    SkeletonData *data = v->skeletonData;
    Skeleton *sk = v->skeleton;
    if (!strcmp(which, "custom-delete-while-set")) {
        // spine-cpp docs pattern: custom skin composed with addSkin (shares), set, then deleted by the user
        Skin *custom = new Skin("custom");
        custom->addSkin(data->findSkin("goblin"));
        sk->setSkin(custom); sk->setSlotsToSetupPose();
        Slot *head = sk->findSlot("head");
        int rcBefore = head->getAttachment()->getRefCount();
        sk->setSkin((Skin *)NULL); // documented way to stop using it
        delete custom;
        lua_pushinteger(L, rcBefore);
        lua_pushinteger(L, head->getAttachment() ? head->getAttachment()->getRefCount() : -1);
        return 2;
    }
    if (!strcmp(which, "copy-delete-while-displayed")) {
        // copySkin creates new attachments owned (refcounted) by the custom skin; delete skin while slot shows a copy
        Skin *custom = new Skin("copied");
        custom->copySkin(data->findSkin("goblin"));
        sk->setSkin(custom); sk->setSlotsToSetupPose();
        Slot *head = sk->findSlot("head");
        Attachment *shown = head->getAttachment();
        int rc = shown->getRefCount();
        sk->setSkin((Skin *)NULL); // spine-cpp docs: setSkin(nullptr); slots keep showing the copies
        delete custom;
        // read every slot's attachment name (UAF under ASan if any slot kept a dangling copy)
        int n = 0;
        for (size_t i = 0; i < sk->getSlots().size(); i++) { Attachment *a = sk->getSlots()[i]->getAttachment(); if (a && a->getName().length()) n++; }
        lua_pushinteger(L, rc); lua_pushinteger(L, n);
        return 2;
    }
    return luaL_error(L, "unknown scenario");
}

