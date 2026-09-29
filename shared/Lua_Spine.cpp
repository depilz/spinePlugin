#include "Lua_Spine.h"
#include "Lua_Skeleton.h"
#include "Lua_Skin.h"
#include "DataHolder.h"
#include "SkeletonDataHolder.h"
#include "SpineTexture.h"
#include "LuaTableHolder.h"
#include "CoronaLibrary.h"

template class DataHolder<Atlas>;

static LuaTableHolder *newGroup;
static LuaTableHolder *group__mt;
static LuaTableHolder *group__index;
static LuaTableHolder *group__newindex;
static LuaTableHolder *groupInsert;
static LuaTableHolder *groupRemoveSelf;
static LuaTableHolder *newMesh;
static LuaTableHolder *pathForFile;
static SpineTextureLoader *textureLoader;

static void loadGroupReferences(lua_State *L)
{
    lua_getglobal(L, "display");
    lua_getfield(L, -1, "newGroup");
    newGroup = new LuaTableHolder(L);
    newGroup->pushTable(L);
    lua_call(L, 0, 1);

    lua_getmetatable(L, -1);
    lua_pushvalue(L, -1);
    group__mt = new LuaTableHolder(L);
    lua_getfield(L, -1, "__index");
    group__index = new LuaTableHolder(L);

    lua_getfield(L, -1, "__newindex");
    group__newindex = new LuaTableHolder(L);
    
    lua_pop(L, 1);

    lua_getfield(L, -1, "insert");
    groupInsert = new LuaTableHolder(L);

    lua_getfield(L, -1, "removeSelf");
    groupRemoveSelf = new LuaTableHolder(L);
    groupRemoveSelf->pushTable(L);
    lua_pushvalue(L, -2);
    lua_call(L, 1, 0);

    lua_pop(L, 1);

    lua_getfield(L, -1, "newMesh");
    newMesh = new LuaTableHolder(L);

    lua_pop(L, 1);

    lua_getglobal(L, "system");
    lua_getfield(L, -1, "pathForFile");
    pathForFile = new LuaTableHolder(L);

    lua_pop(L, 1);
}

// The plugin renders straight alpha only: prints one warning through Lua print when any page declares pma: true.
// A missing or raising print is ignored; the stack is left as it was.
static void warnPremultipliedAlpha(lua_State *L, Atlas *atlas, const char *path)
{
    Vector<AtlasPage *> &pages = atlas->getPages();
    for (size_t i = 0; i < pages.size(); i++)
    {
        if (!pages[i]->pma)
            continue;
        lua_getglobal(L, "print");
        lua_pushfstring(L, "WARNING: plugin.spine: %s: premultiplied-alpha atlas (pma: true) is not supported; "
                           "export with straight alpha", path);
        if (lua_pcall(L, 1, 0, 0) != 0)
            lua_pop(L, 1);
        return;
    }
}

// spine.loadAtlas(path)
int loadAtlas(lua_State *L)
{
    const char *shortPath = luaL_checkstring(L, 1);

    int dirLength;
    char *dir;
    int length;
    const char *data;

    pathForFile->pushTable(L);
    lua_pushvalue(L, 1);
    lua_call(L, 1, 1);

    const char *absPath = lua_tostring(L, -1);
    lua_pop(L, 1);

    if (!absPath)
    {
        luaL_error(L, "File not found: %s", shortPath);
        return 0;
    }

    data = SpineExtension::readFile(absPath, &length);

    if (!data)
    {
        luaL_error(L, "Failed to load atlas file: %s", absPath);
        return 0;
    }

    /* Get directory from atlas path. Allocated only here: nothing between this and its free raises. */
    const char *lastForwardSlash = strrchr(shortPath, '/');
    const char *lastBackwardSlash = strrchr(shortPath, '\\');
    const char *lastSlash = lastForwardSlash > lastBackwardSlash ? lastForwardSlash : lastBackwardSlash;
    if (lastSlash == shortPath)
        lastSlash++; /* Never drop starting slash. */
    dirLength = (int)(lastSlash ? lastSlash - shortPath : 0);
    dir = SpineExtension::calloc<char>(dirLength + 1, __FILE__, __LINE__);
    memcpy(dir, shortPath, dirLength);
    dir[dirLength] = '\0';

    Atlas *atlas = new Atlas(data, length, dir, textureLoader, true);

    SpineExtension::free(data, __FILE__, __LINE__);
    SpineExtension::free(dir, __FILE__, __LINE__);

    if (!textureLoader->failure().empty())
    {
        delete atlas; // unloads the pages that did load
        lua_pushfstring(L, "Failed to load texture: %s", textureLoader->failure().c_str());
        textureLoader->clearFailure();
        return lua_error(L);
    }

    auto atlasUserdata = std::make_shared<DataHolder<Atlas>>(atlas);

    DataHolder<Atlas>::push(L, atlasUserdata);
    warnPremultipliedAlpha(L, atlas, shortPath); // after the push, so a raise here cannot leak the Atlas

    return 1;
}

// Reads with a heap reader and deletes it. On failure pushes the error message, with the reader's reason when it
// recorded one, while the reader is still alive: the caller raises after it is gone.
template <typename Reader>
static SkeletonData *readSkeletonData(lua_State *L, Reader *reader, float scale, const char *absPath)
{
    reader->setScale(scale);
    SkeletonData *skeletonData = reader->readSkeletonDataFile(absPath);
    if (!skeletonData)
    {
        lua_pushfstring(L, "Failed to load skeleton data: %s", absPath);
        if (!reader->getError().isEmpty())
        {
            lua_pushfstring(L, ": %s", reader->getError().buffer());
            lua_concat(L, 2);
        }
    }
    delete reader;
    return skeletonData;
}

// spine.loadSkeletonData(path, atlas[, scale])
int loadSkeletonData(lua_State *L)
{
    // assert path is a string
    const char *shortPath = luaL_checkstring(L, 1);
    float scale = luaL_optnumber(L, 3, 1.0f);

    pathForFile->pushTable(L);
    lua_pushvalue(L, 1);
    lua_call(L, 1, 1);

    const char *absPath = lua_tostring(L, -1);
    lua_pop(L, 1);

    if (!absPath)
    {
        luaL_error(L, "File not found: %s", shortPath);
        return 0;
    }

    // No shared_ptr local: luaL_error below longjmps over C++ destructors. The userdata at 2 keeps the holder alive.
    DataHolder<Atlas> *atlasHolder = DataHolder<Atlas>::check(L, 2).get();
    if (!atlasHolder)
    {
        luaL_error(L, "Invalid atlas");
        return 0;
    }

    Atlas *atlas = atlasHolder->getObject();

    SkeletonData *skeletonData;
    if (strstr(absPath, ".json"))
        skeletonData = readSkeletonData(L, spc::newJson(atlas), scale, absPath);
    else if (strstr(absPath, ".skel"))
        skeletonData = readSkeletonData(L, spc::newBinary(atlas), scale, absPath);
    else
        return luaL_error(L, "Failed to load skeleton data: %s", absPath);

    if (!skeletonData)
        return lua_error(L); // the message readSkeletonData pushed

    auto skeletonDataUserdata = std::make_shared<SkeletonDataHolder>(skeletonData, L, 2);

    DataHolder<SkeletonData>::push(L, skeletonDataUserdata);

    return 1;
}

// spine.create(skeletonData [,listener])
int create(lua_State *L)
{
    bool hasListener = lua_gettop(L) > 1 && !lua_isnil(L, 2);
    // Validate before taking the shared_ptr below: luaL_error longjmps over C++ destructors.
    if (hasListener)
    {
        luaL_checktype(L, 2, LUA_TFUNCTION);
    }

    auto skeletonDataUserdata = DataHolder<SkeletonData>::check(L, 1);
    if (!skeletonDataUserdata)
    {
        luaL_error(L, "Invalid skeletonData");
        return 0;
    }

    SkeletonData *skeletonData = skeletonDataUserdata->getObject();

    int listenerRef = LUA_NOREF;
    if (hasListener)
    {
        lua_pushvalue(L, 2); // luaL_ref pops the top, which is not the listener when extra args follow
        listenerRef = luaL_ref(L, LUA_REGISTRYINDEX);
    }

    Skeleton *skeleton = spc::newSkeleton(skeletonData);

    AnimationStateData *stateData = spc::newStateData(skeletonData);
    AnimationState *state = spc::newState(stateData);

    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)lua_newuserdata(L, sizeof(SpineSkeleton));
    new (skeletonUserdata) SpineSkeleton(L);
    skeletonUserdata->skeleton = skeleton;
    skeletonUserdata->state = state;
    skeletonUserdata->stateData = stateData;
    skeletonUserdata->skeletonData = skeletonData;
    skeletonUserdata->dataOwner = skeletonDataUserdata;
    // Pose, never Update/Reset: those consume the physics reset at time 0 and kick the first real frame.
    skeleton->updateWorldTransform(Physics_Pose);

    getSkeletonMt(L);
    lua_setmetatable(L, -2);

    newGroup->pushTable(L);
    lua_call(L, 0, 1);

    lua_pushstring(L, "_skeleton");
    lua_pushvalue(L, -3);
    lua_rawset(L, -3);

    // The userdata lives only through group._skeleton; the display object is event.target until dispose.
    skeletonUserdata->luaSelf = LuaTableHolder(L, -1);
    // The state listener lives until dispose(); setListener only swaps its function.
    skeletonUserdata->stateListener = new LuaAnimationStateListener(L, &skeletonUserdata->luaSelf, skeletonUserdata->alive,
                                                                    &skeletonUserdata->disposeRequested);
    skeletonUserdata->stateListener->setFunction(listenerRef);
    state->setListener(skeletonUserdata->stateListener);

    lua_getfield(L, -1, "addEventListener");
    lua_pushvalue(L, -2);
    lua_pushstring(L, "finalize");
    lua_pushcfunction(L, spine_onFinalize);
    lua_call(L, 3, 0);

    skeletonUserdata->group__mt = group__mt;
    skeletonUserdata->groupmt__index = group__index;
    skeletonUserdata->groupmt__newindex = group__newindex;
    skeletonUserdata->groupInsert = groupInsert;
    skeletonUserdata->groupRemoveSelf = groupRemoveSelf;
    skeletonUserdata->newMesh = newMesh;
    skeletonUserdata->newGroup = newGroup;

    getSpineObjectMt(L);
    lua_setmetatable(L, -2);

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

CORONA_EXPORT int SPINE_PLUGIN_LUAOPEN(lua_State *L) {

    Bone::setYDown(true); // Solar2D is y-down; the 4.3 runtime's default already is

    lua_newtable(L);

    const luaL_Reg spine_functions[] = {
        {"loadAtlas", loadAtlas},
        {"loadSkeletonData", loadSkeletonData},
        {"create", create},
        {NULL, NULL}
    };

    luaL_register(L, NULL, spine_functions);
    lua_pushstring(L, &SPINE_PLUGIN_VERSION[1]); // "v2.0.0" -> "2.0.0"
    lua_setfield(L, -2, "version");
    lua_pushstring(L, SPINE_VERSION_STRING);
    lua_setfield(L, -2, "runtimeVersion");

    textureLoader = new SpineTextureLoader(L);
    loadGroupReferences(L);
    resetDisposeQueue();

    // Initialize metatables
    getSkinMt(L);
    lua_pop(L, 1); // pop the metatable

    printf("Solar2d Spine plugin %s loaded with Spine %s\n", SPINE_PLUGIN_VERSION, SPINE_VERSION_STRING);

    return 1;
}
