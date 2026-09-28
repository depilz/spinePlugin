// Headless fixture: real Lua bindings and Spine runtime, without Solar2D rendering (4.3 counterpart of
// attachment_fixture.cpp).
#include "Lua_Skeleton.h"
#include "Lua_Slot.h"
#include "spine/Extension.h"
#include "SpineRenderer.h"
#include <cstdlib>

void engine_removeMesh(lua_State *, LuaTableHolder *) { std::abort(); }

void renderCommands(lua_State *, SpineSkeleton *, RenderCommand *, MeshManager &, int) { std::abort(); }

extern "C" lua_State *CoronaLuaGetCoronaThread(lua_State *L) { return L; }
extern "C" int CoronaLuaDoCall(lua_State *L, int narg, int nresults) { int s = lua_pcall(L, narg, nresults, 0); if (s && !lua_isnil(L, -1)) { fprintf(stderr, "CoronaLuaDoCall: %s\n", lua_isstring(L, -1) ? lua_tostring(L, -1) : "(error object is not a string)"); lua_pop(L, 1); } return s; }
SpineExtension *spine::getDefaultExtension() { return new DefaultSpineExtension(); }

static int createFixture(lua_State *L) {
    std::shared_ptr<DataHolder<SkeletonData>> dataOwner;
    if (lua_istable(L, 1)) {
        lua_getfield(L, 1, "_skeleton");
        dataOwner = ((SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton"))->dataOwner;
        lua_pop(L, 1);
    } else {
        auto *data = new SkeletonData();
        dataOwner = std::make_shared<DataHolder<SkeletonData>>(data);
        auto *bone = new BoneData(0, "root", nullptr);
        data->getBones().add(bone);
        auto *slot = new SlotData(0, "medal", *bone);
        slot->setAttachmentName("medal");
        data->getSlots().add(slot);
        data->getSlots().add(new SlotData(1, "empty", *bone));
        auto *base = new Skin("default");
        base->setAttachment(0, "medal", new RegionAttachment("art/base", new Sequence(1, false)));
        base->setAttachment(0, "fallback", new RegionAttachment("art/fallback", new Sequence(1, false)));
        base->setAttachment(0, "null", new RegionAttachment("art/null", new Sequence(1, false)));
        base->setAttachment(0, "mesh", new MeshAttachment("art/mesh", new Sequence(1, false)));
        data->getSkins().add(base);
        data->setDefaultSkin(base);
        auto *gold = new Skin("gold");
        gold->setAttachment(0, "medal", new RegionAttachment("art/gold", new Sequence(1, false)));
        data->getSkins().add(gold);
        Array<Timeline *> timelines;
        Array<int> bones;
        auto *timeline = new AttachmentTimeline(1, 0);
        timeline->setFrame(0, 0, "medal");
        timelines.add(timeline);
        auto *animation = new Animation("medal");
        animation->setTimelines(timelines, bones);
        animation->setDuration(1);
        data->getAnimations().add(animation);
    }
    lua_newtable(L);
    auto *value = (SpineSkeleton *)lua_newuserdata(L, sizeof(SpineSkeleton));
    new (value) SpineSkeleton(L);
    value->dataOwner = dataOwner;
    value->skeletonData = dataOwner->getObject();
    value->skeleton = new Skeleton(*value->skeletonData);
    value->stateData = new AnimationStateData(*value->skeletonData);
    value->state = new AnimationState(*value->stateData);
    getSkeletonMt(L);
    lua_setmetatable(L, -2);
    lua_setfield(L, -2, "_skeleton");
    getSpineObjectMt(L);
    lua_setmetatable(L, -2);
    return 1;
}

static int disposeFixture(lua_State *L) {
    lua_getfield(L, 1, "_skeleton");
    auto *value = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    lua_pushnil(L);
    lua_setmetatable(L, -2);
    value->~SpineSkeleton();
    lua_pushnil(L);
    lua_setmetatable(L, 1);
    lua_pushnil(L);
    lua_setfield(L, 1, "_skeleton");
    return 0;
}

extern "C" int luaopen_attachment_fixture(lua_State *L) {
    lua_newtable(L);
    lua_pushcfunction(L, createFixture);
    lua_setfield(L, -2, "new");
    lua_pushcfunction(L, disposeFixture);
    lua_setfield(L, -2, "dispose");
    return 1;
}
