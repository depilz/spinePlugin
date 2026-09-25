// Headless fixture: real Lua bindings + real Spine runtime,
// real exported skeletons from Corona/spines, stubbed Solar2D rendering.
// Mirrors spine.create() in shared/Lua_Spine.cpp minus the display group.
#include "Lua_Skeleton.h"
#include "Lua_Slot.h"
#include "spine/Extension.h"
#include "SpineRenderer.h"
#include <cstdlib>
#include <cstring>
#include <cstdio>

void engine_removeMesh(lua_State *, LuaTableHolder *) { std::fprintf(stderr, "engine_removeMesh called in headless fixture\n"); std::abort(); }
void renderCommands(lua_State *, SpineSkeleton *, RenderCommand *, MeshManager &, int) { std::fprintf(stderr, "renderCommands called in headless fixture\n"); std::abort(); }
extern "C" lua_State *CoronaLuaGetCoronaThread(lua_State *L) { return L; }
SpineExtension *spine::getDefaultExtension() { return new DefaultSpineExtension(); }

struct StubTextureLoader : public TextureLoader {
    int loads = 0, unloads = 0;
    void load(AtlasPage &page, const String &path) override { ++loads; page.texture = (void *)0x1; }
    void unload(void *) override { ++unloads; }
};
static StubTextureLoader g_loader;

// Owns atlas + skeleton data together (atlas must outlive data).
struct RealData {
    Atlas *atlas;
    SkeletonData *data;
};
static std::shared_ptr<DataHolder<SkeletonData>> *checkData(lua_State *L, int idx) {
    return (std::shared_ptr<DataHolder<SkeletonData>> *)luaL_checkudata(L, idx, "DataHolder");
}

// fixture.loadData(atlasPath, skelOrJsonPath [, scale]) -> DataHolder<SkeletonData> userdata
static int loadData(lua_State *L) {
    const char *atlasPath = luaL_checkstring(L, 1);
    const char *skelPath = luaL_checkstring(L, 2);
    float scale = (float)luaL_optnumber(L, 3, 1.0);
    // Atlas intentionally leaked for the process lifetime (test-only simplification).
    Atlas *atlas = new Atlas(atlasPath, &g_loader, true);
    if (atlas->getPages().size() == 0) luaL_error(L, "atlas load failed: %s", atlasPath);
    SkeletonData *data = nullptr;
    if (std::strstr(skelPath, ".json")) {
        SkeletonJson json(atlas); json.setScale(scale);
        data = json.readSkeletonDataFile(skelPath);
        if (!data) luaL_error(L, "json load failed: %s", json.getError().buffer());
    } else {
        SkeletonBinary bin(atlas); bin.setScale(scale);
        data = bin.readSkeletonDataFile(skelPath);
        if (!data) luaL_error(L, "binary load failed: %s", bin.getError().buffer());
    }
    auto holder = std::make_shared<DataHolder<SkeletonData>>(data);
    DataHolder<SkeletonData>::push(L, holder);
    return 1;
}

// fixture.create(dataHolder) -> spine object table { _skeleton = SpineSkeleton userdata } (no display group)
static int create(lua_State *L) {
    auto holder = *checkData(L, 1);
    SkeletonData *skeletonData = holder->getObject();
    lua_newtable(L);
    auto *value = (SpineSkeleton *)lua_newuserdata(L, sizeof(SpineSkeleton));
    new (value) SpineSkeleton(L);
    value->dataOwner = holder;
    value->skeletonData = skeletonData;
    value->skeleton = new Skeleton(skeletonData);
    value->skeleton->setScaleY(-1);
    value->stateData = new AnimationStateData(skeletonData);
    value->state = new AnimationState(value->stateData);
    value->luaSelf = new LuaTableHolder();
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

// fixture.worldTransform(obj): skeleton:updateWorldTransform(Physics_None) without rendering.
static int worldTransform(lua_State *L) {
    lua_getfield(L, 1, "_skeleton");
    auto *value = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    value->skeleton->updateWorldTransform(Physics_None);
    return 0;
}

// fixture.slotAttachments(obj) -> { [slotName] = attachmentName or false } (raw runtime state)
static int slotAttachments(lua_State *L) {
    lua_getfield(L, 1, "_skeleton");
    auto *value = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    lua_newtable(L);
    auto &slots = value->skeleton->getSlots();
    for (size_t i = 0; i < slots.size(); ++i) {
        Attachment *a = slots[i]->getAttachment();
        if (a) lua_pushstring(L, a->getName().buffer()); else lua_pushboolean(L, 0);
        lua_setfield(L, -2, slots[i]->getData().getName().buffer());
    }
    return 1;
}

// fixture.activeBones(obj) -> { [boneName] = bool } after updateCache
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

extern "C" int luaopen_realdata_fixture(lua_State *L) {
    lua_newtable(L);
    const luaL_Reg fns[] = {
        {"loadData", loadData}, {"create", create}, {"dispose", dispose},
        {"worldTransform", worldTransform}, {"slotAttachments", slotAttachments},
        {"activeBones", activeBones}, {"textureStats", textureStats}, {NULL, NULL}};
    luaL_register(L, NULL, fns);
    return 1;
}
