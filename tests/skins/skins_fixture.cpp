// Skins fixture: the headless fixture (tests/host/realdata_fixture.cpp) plus skins-model introspection,
// usedMemory/renderStats/renderStats2 and timelineAttachments. loadData builds the plugin's real
// SkeletonDataHolder holding a Lua ref to a DataHolder<Atlas> userdata, exactly like spine.loadSkeletonData
// (shared/Lua_Spine.cpp:126-179), so the atlas is freed with the data.
#include "Lua_Skeleton.h"
#include "Lua_Slot.h"
#include "SkeletonDataHolder.h"
#include "skins_compat.h"
#include "spine/Extension.h"
#include "spine/Debug.h"
#include "spine/DeformTimeline.h"
#include "spine/SequenceTimeline.h"
#include "spine/SkeletonRenderer.h"
#include "SpineRenderer.h"
#include <cstdlib>
#include <cstring>
#include <cstdio>
#include <set>
#include <string>
#include <vector>
#include <cstdint>
#include <memory>

void engine_removeMesh(lua_State *, LuaTableHolder *) { std::fprintf(stderr, "engine_removeMesh called in headless fixture\n"); std::abort(); }
void renderCommands(lua_State *, SpineSkeleton *, RenderCommand *, MeshManager &, int) { std::fprintf(stderr, "renderCommands called in headless fixture\n"); std::abort(); }
extern "C" lua_State *CoronaLuaGetCoronaThread(lua_State *L) { return L; }
extern "C" int CoronaLuaDoCall(lua_State *L, int narg, int nresults) { int s = lua_pcall(L, narg, nresults, 0); if (s && !lua_isnil(L, -1)) { fprintf(stderr, "CoronaLuaDoCall: %s\n", lua_isstring(L, -1) ? lua_tostring(L, -1) : "(error object is not a string)"); lua_pop(L, 1); } return s; }

// DebugExtension leaves _usedMemory uninitialized (runtime/spine-4.2/spine/Debug.h:55-57); clearAllocations() zeroes it.
static DebugExtension *g_debugExt = nullptr;
SpineExtension *spine::getDefaultExtension() {
    g_debugExt = new DebugExtension(new DefaultSpineExtension());
    g_debugExt->clearAllocations();
    return g_debugExt;
}

struct StubTextureLoader : public TextureLoader {
    int loads = 0, unloads = 0;
    void load(AtlasPage &page, const String &path) override { ++loads; page.texture = (void *)(uintptr_t)(0x1000 + loads); }
    void unload(void *) override { ++unloads; }
};
static StubTextureLoader g_loader;

static int g_dataCreated = 0, g_dataFreed = 0;

static std::shared_ptr<DataHolder<SkeletonData>> *checkData(lua_State *L, int idx) {
    return (std::shared_ptr<DataHolder<SkeletonData>> *)luaL_checkudata(L, idx, "SkeletonData");
}

// fixture.loadAtlas(path) -> DataHolder<Atlas> userdata (like spine.loadAtlas, stub textures)
static int loadAtlas(lua_State *L) {
    const char *atlasPath = luaL_checkstring(L, 1);
    Atlas *atlas = new Atlas(atlasPath, &g_loader, true);
    if (atlas->getPages().size() == 0) { delete atlas; return luaL_error(L, "atlas load failed: %s", atlasPath); }
    DataHolder<Atlas>::push(L, std::make_shared<DataHolder<Atlas>>(atlas));
    return 1;
}

// fixture.loadData(atlasPathOrAtlasHolder, skelOrJsonPath [, scale]) -> DataHolder<SkeletonData> userdata
// Backed by the real SkeletonDataHolder (like spine.loadSkeletonData).
static int loadData(lua_State *L) {
    const char *skelPath = luaL_checkstring(L, 2);
    float scale = (float)luaL_optnumber(L, 3, 1.0);
    int atlasIndex;
    if (lua_type(L, 1) == LUA_TSTRING) {
        lua_pushcfunction(L, loadAtlas);
        lua_pushvalue(L, 1);
        lua_call(L, 1, 1);
        atlasIndex = lua_gettop(L);
    } else {
        luaL_checkudata(L, 1, "Atlas");
        atlasIndex = 1;
    }
    Atlas *atlas = (*(std::shared_ptr<DataHolder<Atlas>> *)lua_touserdata(L, atlasIndex))->getObject();
    SkeletonData *data = nullptr;
    if (std::strstr(skelPath, ".json")) {
        std::unique_ptr<SkeletonJson> json(spc::newJson(atlas));
        json->setScale(scale);
        data = json->readSkeletonDataFile(skelPath);
        if (!data) return luaL_error(L, "json load failed: %s", json->getError().buffer());
    } else {
        std::unique_ptr<SkeletonBinary> bin(spc::newBinary(atlas));
        bin->setScale(scale);
        data = bin->readSkeletonDataFile(skelPath);
        if (!data) return luaL_error(L, "binary load failed: %s", bin->getError().buffer());
    }
    ++g_dataCreated;
    // Real SkeletonDataHolder; the custom deleter only counts frees (then runs the real destructor).
    std::shared_ptr<SkeletonDataHolder> holder(new SkeletonDataHolder(data, L, atlasIndex),
                                               [](SkeletonDataHolder *p) { delete p; ++g_dataFreed; });
    DataHolder<SkeletonData>::push(L, holder);
    return 1;
}

// fixture.dataStats() -> created, freed (SkeletonDataHolder destructions)
static int dataStats(lua_State *L) { lua_pushinteger(L, g_dataCreated); lua_pushinteger(L, g_dataFreed); return 2; }

// fixture.create(dataHolder) -> spine object table { _skeleton = SpineSkeleton userdata } (no display group)
static int create(lua_State *L) {
    auto holder = *checkData(L, 1);
    SkeletonData *skeletonData = holder->getObject();
    lua_newtable(L);
    auto *value = (SpineSkeleton *)lua_newuserdata(L, sizeof(SpineSkeleton));
    new (value) SpineSkeleton(L);
    value->dataOwner = holder;
    value->skeletonData = skeletonData;
    value->skeleton = spc::newSkeleton(skeletonData);
    value->stateData = spc::newStateData(skeletonData);
    value->state = spc::newState(value->stateData);
    getSkeletonMt(L);
    lua_setmetatable(L, -2);
    lua_setfield(L, -2, "_skeleton");
    getSpineObjectMt(L);
    lua_setmetatable(L, -2);
    return 1;
}

// fixture.dispose(obj): runs the SpineSkeleton destructor like removeSelf/gc would.
static int dispose(lua_State *L) {
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

static int worldTransform(lua_State *L) {
    lua_getfield(L, 1, "_skeleton");
    auto *value = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    value->skeleton->updateWorldTransform(Physics_None);
    return 0;
}

static int slotAttachments(lua_State *L) {
    lua_getfield(L, 1, "_skeleton");
    auto *value = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    lua_newtable(L);
    auto &slots = value->skeleton->getSlots();
    for (size_t i = 0; i < slots.size(); ++i) {
        Attachment *a = spc::applied(*slots[i]).getAttachment();
        if (a) lua_pushstring(L, a->getName().buffer()); else lua_pushboolean(L, 0);
        lua_setfield(L, -2, slots[i]->getData().getName().buffer());
    }
    return 1;
}

static int activeBones(lua_State *L) {
    lua_getfield(L, 1, "_skeleton");
    auto *value = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    lua_newtable(L);
    auto &bones = value->skeleton->getBones();
    for (size_t i = 0; i < bones.size(); ++i) {
        lua_pushboolean(L, bones[i]->isActive());
        lua_setfield(L, -2, bones[i]->getData().getName().buffer());
    }
    return 1;
}

static int textureStats(lua_State *L) {
    lua_pushinteger(L, g_loader.loads);
    lua_pushinteger(L, g_loader.unloads);
    return 2;
}

// spine-allocated bytes (DebugExtension, zeroed at creation)
static int usedMemory(lua_State *L) {
    lua_pushnumber(L, g_debugExt ? (lua_Number)g_debugExt->getUsedMemory() : -1);
    return 1;
}
static int reportLeaks(lua_State *L) { if (g_debugExt) g_debugExt->reportLeaks(); return 0; }

static int renderStats(lua_State *L) {
    lua_getfield(L, 1, "_skeleton");
    auto *value = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    value->skeleton->updateWorldTransform(Physics_None);
    SkeletonRenderer renderer;
    std::vector<int> none;
    RenderCommand *cmd = renderer.render(*value->skeleton, none);
    int n = 0, verts = 0; std::set<void *> tex; std::string seq;
    for (; cmd; cmd = cmd->next) {
        ++n; verts += cmd->numVertices; tex.insert(cmd->texture);
        char buf[32]; std::snprintf(buf, sizeof buf, "%s%d", seq.empty() ? "" : ",", (int)((uintptr_t)cmd->texture - 0x1000));
        seq += buf;
    }
    lua_pushinteger(L, n); lua_pushinteger(L, (int)tex.size()); lua_pushinteger(L, verts); lua_pushstring(L, seq.c_str());
    return 4;
}


// fx.renderStats2(obj, {injectionSlotName,...}) -> commands, vertices, injectionCommands, {slotName -> vertices}
// Runs the tree's vendored SkeletonRenderer::render (no batching of per-slot data is assumed; counts are totals).
static int renderStats2(lua_State *L) {
    lua_getfield(L, 1, "_skeleton");
    auto *value = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    lua_pop(L, 1);
    std::vector<int> inj;
    if (lua_istable(L, 2)) {
        for (int i = 1;; i++) {
            lua_rawgeti(L, 2, i);
            if (lua_isnil(L, -1)) { lua_pop(L, 1); break; }
            Slot *s = value->skeleton->findSlot(lua_tostring(L, -1));
            if (s) inj.push_back(s->getData().getIndex());
            lua_pop(L, 1);
        }
    }
    value->skeleton->updateWorldTransform(Physics_None);
    SkeletonRenderer renderer;
    RenderCommand *cmd = renderer.render(*value->skeleton, inj);
    int n = 0, verts = 0, injCmds = 0;
    for (; cmd; cmd = cmd->next) { ++n; verts += cmd->numVertices; if (cmd->injectionSlotIndex >= 0) ++injCmds; }
    lua_pushinteger(L, n); lua_pushinteger(L, verts); lua_pushinteger(L, injCmds);
    return 3;
}

#include "skins_model_ext.inc"

// fx.timelineAttachments(obj) -> array of {anim=, kind="deform"|"sequence", name=, ptr=, refCount=}
static int timelineAttachments(lua_State *L) {
    SpineSkeleton *v = objSkel(L, 1);
    lua_newtable(L);
    int n = 0;
    auto &anims = v->skeletonData->getAnimations();
    for (size_t i = 0; i < anims.size(); ++i) {
        auto &tls = anims[i]->getTimelines();
        for (size_t j = 0; j < tls.size(); ++j) {
            Attachment *a = nullptr; const char *kind = nullptr;
            if (tls[j]->getRTTI().instanceOf(DeformTimeline::rtti)) { a = skc::timelineAttachment(*static_cast<DeformTimeline *>(tls[j])); kind = "deform"; }
            else if (tls[j]->getRTTI().instanceOf(SequenceTimeline::rtti)) { a = skc::timelineAttachment(*static_cast<SequenceTimeline *>(tls[j])); kind = "sequence"; }
            if (!a) continue;
            lua_newtable(L);
            lua_pushstring(L, anims[i]->getName().buffer()); lua_setfield(L, -2, "anim");
            lua_pushstring(L, kind); lua_setfield(L, -2, "kind");
            pushPtr(L, a); lua_setfield(L, -2, "ptr");
            lua_rawseti(L, -2, ++n);
        }
    }
    return 1;
}

extern "C" int luaopen_realdata_fixture(lua_State *L) {
    Bone::setYDown(true); // the plugin's configuration (SPINE_PLUGIN_LUAOPEN in shared/Lua_Spine.cpp)
    lua_newtable(L);
    const luaL_Reg fns[] = {
        {"loadAtlas", loadAtlas}, {"loadData", loadData}, {"dataStats", dataStats},
        {"create", create}, {"dispose", dispose},
        {"worldTransform", worldTransform}, {"slotAttachments", slotAttachments},
        {"activeBones", activeBones}, {"textureStats", textureStats},
        {"usedMemory", usedMemory}, {"reportLeaks", reportLeaks}, {"renderStats", renderStats},
        {"slotInfo", slotInfo}, {"dataSkinEntry", dataSkinEntry}, {"luaSkinEntry", luaSkinEntry}, {"setSkinRaw", setSkinRaw},
        {"skinName", skinName}, {"updateCache", updateCacheFn}, {"activeConstraints", activeConstraints}, {"updateCacheCount", updateCacheCount},
        {"cppSkinScenario", cppSkinScenario}, {"renderStats2", renderStats2}, {"timelineAttachments", timelineAttachments}, {NULL, NULL}};
    luaL_register(L, NULL, fns);
    return 1;
}
