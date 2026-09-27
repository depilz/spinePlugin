// Animation fixture: the shared headless fixture (tests/host/realdata_fixture.cpp) plus createPlugin, rawTrackCount
// and entryPtr, registered on the same require("realdata_fixture") module.
#define luaopen_realdata_fixture realdata_fixture_base
#include "../host/realdata_fixture.cpp"
#undef luaopen_realdata_fixture

// fixture.createPlugin(dataHolder [, listener]) -> mirrors shared/Lua_Spine.cpp create() (lines 177-242 at 1.5.0)
// exactly (luaSelf = LuaTableHolder(L) taken right after lua_newuserdata, listener installed the same way),
// except newGroup() is replaced by a plain table (no display group).
static int createPlugin(lua_State *L) {
    bool hasListener = lua_gettop(L) > 1 && !lua_isnil(L, 2);
    auto holder = *checkData(L, 1);
    SkeletonData *skeletonData = holder->getObject();
    int listenerRef = LUA_NOREF;
    if (hasListener) {
        luaL_checktype(L, 2, LUA_TFUNCTION);
        listenerRef = luaL_ref(L, LUA_REGISTRYINDEX);
    }
    Skeleton *skeleton = spc::newSkeleton(skeletonData);
#if !SPINE_43()
    skeleton->setScaleY(-1); // 4.3: Bone::yDown is true by default
#endif
    AnimationStateData *stateData = spc::newStateData(skeletonData);
    AnimationState *state = spc::newState(stateData);
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)lua_newuserdata(L, sizeof(SpineSkeleton));
    new (skeletonUserdata) SpineSkeleton(L);
    skeletonUserdata->skeleton = skeleton;
    skeletonUserdata->state = state;
    skeletonUserdata->stateData = stateData;
    skeletonUserdata->skeletonData = skeletonData;
    skeletonUserdata->dataOwner = holder;
    skeletonUserdata->luaSelf = new LuaTableHolder(L);
    skeletonUserdata->luaSelf->pushTable(L);
    if (hasListener) {
        LuaAnimationStateListener *stateListener = new LuaAnimationStateListener(L, skeletonUserdata->luaSelf, listenerRef);
        skeletonUserdata->stateListener = stateListener;
        state->setListener(stateListener);
    }
    getSkeletonMt(L);
    lua_setmetatable(L, -2);
    lua_newtable(L); // stands in for newGroup()
    lua_pushstring(L, "_skeleton");
    lua_pushvalue(L, -3);
    lua_rawset(L, -3);
    getSpineObjectMt(L);
    lua_setmetatable(L, -2);
    return 1;
}

// fixture.poolInfo(obj) -> number of tracks (raw vector size)
static int rawTrackCount(lua_State *L) {
    lua_getfield(L, 1, "_skeleton");
    auto *value = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    lua_pushinteger(L, (lua_Integer)value->state->getTracks().size());
    return 1;
}

// fixture.entryPtr(entryUserdata) -> lightuserdata-ish string of raw TrackEntry* (for aliasing checks)
static int entryPtr(lua_State *L) {
    struct E { lua_State *L; TrackEntry *entry; };
    E *e = (E *)luaL_checkudata(L, 1, "SpineTrackEntry");
    char buf[32]; std::snprintf(buf, sizeof buf, "%p", (void *)e->entry);
    lua_pushstring(L, buf);
    return 1;
}

extern "C" int luaopen_realdata_fixture(lua_State *L) {
    realdata_fixture_base(L);
    const luaL_Reg fns[] = {
        {"createPlugin", createPlugin}, {"rawTrackCount", rawTrackCount}, {"entryPtr", entryPtr}, {NULL, NULL}};
    luaL_register(L, NULL, fns);
    return 1;
}
