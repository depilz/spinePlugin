// Animation helpers: native reads the Lua surface does not expose, added to the lifecycle host's __native table
// (tests/lifecycle/host.c, -DHOST_NATIVE=animation_native). Objects come from the real spine.create().
#include "Lua_Skeleton.h"
#include <cstdio>

static SpineSkeleton *skeletonOf(lua_State *L) {
    lua_getfield(L, 1, "_skeleton");
    return (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
}

// __native.rawTrackCount(obj) -> number of tracks (raw vector size)
static int rawTrackCount(lua_State *L) {
    lua_pushinteger(L, (lua_Integer)skeletonOf(L)->state->getTracks().size());
    return 1;
}

// __native.entryPtr(entryUserdata) -> lightuserdata-ish string of raw TrackEntry* (for aliasing checks)
static int entryPtr(lua_State *L) {
    struct E { lua_State *L; TrackEntry *entry; };
    E *e = (E *)luaL_checkudata(L, 1, "SpineTrackEntry");
    char buf[32]; std::snprintf(buf, sizeof buf, "%p", (void *)e->entry);
    lua_pushstring(L, buf);
    return 1;
}

// __native.sequenceIndex(obj, slotName) -> the slot's sequence index as the timelines left it (-1 = setup frame)
static int sequenceIndex(lua_State *L) {
    Slot *slot = skeletonOf(L)->skeleton->findSlot(luaL_checkstring(L, 2));
    if (!slot) return luaL_error(L, "no slot %s", lua_tostring(L, 2));
    lua_pushinteger(L, spc::pose(*slot).getSequenceIndex());
    return 1;
}

extern "C" int animation_native(lua_State *L) {
    const luaL_Reg fns[] = {
        {"rawTrackCount", rawTrackCount}, {"entryPtr", entryPtr}, {"sequenceIndex", sequenceIndex}, {NULL, NULL}};
    luaL_register(L, NULL, fns);
    return 0;
}
