#include "Lua_Spine.h"
#include "Lua_Skeleton.h"
#include "DataHolder.h"
#include "SkeletonDataHolder.h"
#include "SpineTexture.h"
#include "LuaTableHolder.h"

template class DataHolder<Atlas>;

static LuaTableHolder *newGroup;
static LuaTableHolder *group__index;
static LuaTableHolder *group__newindex;
static LuaTableHolder *groupInsert;
static LuaTableHolder *groupRemoveSelf;
static LuaTableHolder *newMesh;
static SpineTextureLoader *textureLoader;

static void loadGroupReferences(lua_State *L)
{
    lua_getglobal(L, "display");
    lua_getfield(L, -1, "newGroup");
    newGroup = new LuaTableHolder(L);
    newGroup->pushTable();
    lua_call(L, 0, 1);

    lua_getmetatable(L, -1);
    lua_getfield(L, -1, "__index");
    group__index = new LuaTableHolder(L);

    lua_getfield(L, -1, "__newindex");
    group__newindex = new LuaTableHolder(L);
    
    lua_pop(L, 1);

    lua_getfield(L, -1, "insert");
    groupInsert = new LuaTableHolder(L);

    lua_getfield(L, -1, "removeSelf");
    groupRemoveSelf = new LuaTableHolder(L);
    groupRemoveSelf->pushTable();
    lua_pushvalue(L, -2);
    lua_call(L, 1, 0);

    lua_pop(L, 1);

    lua_getfield(L, -1, "newMesh");
    newMesh = new LuaTableHolder(L);

    lua_pop(L, 1);
}

// spine.loadAtlas(absPath)
int loadAtlas(lua_State *L)
{
    const char *atlasFile = luaL_checkstring(L, 1);

    auto *atlas = new Atlas(atlasFile, textureLoader);
    auto atlasUserdata = std::make_shared<DataHolder<Atlas>>(atlas);

    DataHolder<Atlas>::push(L, atlasUserdata);

    return 1;
}

// spine.loadSkeletonData(absPath, atlas[, scale])
int loadSkeletonData(lua_State *L)
{
    const char *skeletonFile = luaL_checkstring(L, 1);

    auto atlasUserdata = DataHolder<Atlas>::check(L, 2);
    Atlas *atlas = atlasUserdata->getObject();

    float scale = luaL_optnumber(L, 3, 1.0f);

    SkeletonData *skeletonData = nullptr;
    if (strstr(skeletonFile, ".json"))
    {
        SkeletonJson *json = new SkeletonJson(atlas);
        json->setScale(scale);
        skeletonData = json->readSkeletonDataFile(skeletonFile);
        delete json;
    }
    else if (strstr(skeletonFile, ".skel"))
    {
        SkeletonBinary *binary = new SkeletonBinary(atlas);
        binary->setScale(scale);
        skeletonData = binary->readSkeletonDataFile(skeletonFile);
        delete binary;
    }

    if (!skeletonData)
    {
        luaL_error(L, "Failed to load skeleton data");
        return 0;
    }

    auto skeletonDataUserdata = std::make_shared<SkeletonDataHolder>(skeletonData, L, 2);

    DataHolder<SkeletonData>::push(L, skeletonDataUserdata);

    return 1;
}

// spine.create(skeletonData [,listener])
int create(lua_State *L)
{
    bool hasListener = lua_gettop(L) > 1 && !lua_isnil(L, 2);

    auto skeletonDataUserdata = DataHolder<SkeletonData>::check(L, 1);
    SkeletonData *skeletonData = skeletonDataUserdata->getObject();

    int listenerRef;
    if (hasListener)
    {
        luaL_checktype(L, 2, LUA_TFUNCTION);
        listenerRef = luaL_ref(L, LUA_REGISTRYINDEX);
    }

    Skeleton *skeleton = new Skeleton(skeletonData);
    AnimationStateData *stateData = new AnimationStateData(skeletonData);
    AnimationState *state = new AnimationState(stateData);

    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)lua_newuserdata(L, sizeof(SpineSkeleton));
    new (skeletonUserdata) SpineSkeleton(L);
    skeletonUserdata->skeleton = skeleton;
    skeletonUserdata->state = state;
    skeletonUserdata->stateData = stateData;
    skeletonUserdata->skeletonData = skeletonData;

    lua_pushvalue(L, 1);
    skeletonUserdata->skeletonDataRef = luaL_ref(L, LUA_REGISTRYINDEX);

    if (hasListener)
    {
        LuaAnimationStateListener *stateListener = new LuaAnimationStateListener(L, listenerRef);
        skeletonUserdata->stateListener = stateListener;
        state->setListener(stateListener);
    }

    getSkeletonMt(L);
    lua_setmetatable(L, -2);

    newGroup->pushTable();
    lua_call(L, 0, 1);

    lua_pushstring(L, "_skeleton");
    lua_pushvalue(L, -3);
    lua_rawset(L, -3);

    skeletonUserdata->groupmt__index = group__index;
    skeletonUserdata->groupmt__newindex = group__newindex;
    skeletonUserdata->groupInsert = groupInsert;
    skeletonUserdata->groupRemoveSelf = groupRemoveSelf;
    skeletonUserdata->newMesh = newMesh;

    getSpineObjectMt(L);
    lua_setmetatable(L, -2);

    return 1;
}

int luaopen_spine(lua_State *L)
{
    const luaL_Reg spine_functions[] = {
        {"loadAtlas", loadAtlas},
        {"loadSkeletonData", loadSkeletonData},
        {"create", create},
        {NULL, NULL}
    };

    const char *plugin_name = lua_tostring(L, 1);
    luaL_register(L, plugin_name, spine_functions);

    textureLoader = new SpineTextureLoader(L);
    loadGroupReferences(L);

    const char *pluginVersion = "v1.0";
    const char *spineVersion = "4.2.XX";
    printf("Spine plugin %s loaded. Spine runtime version: %s\n", pluginVersion, spineVersion);

    return 1;
}

Solar2dExtension::Solar2dExtension() : DefaultSpineExtension()
{
}

Solar2dExtension::~Solar2dExtension() {}

SpineExtension *spine::getDefaultExtension()
{
    return new Solar2dExtension();
}
