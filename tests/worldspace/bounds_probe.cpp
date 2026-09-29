// Worldspace probes: the vendored SkeletonBounds hit test (the oracle) and a Spine skeleton transform setter as the
// global table __probe, added to the lifecycle host
// (tests/lifecycle/host.c, -DHOST_NATIVE=worldspace_native). Objects come from the real spine.create().
#include "Lua_Skeleton.h"

// __probe.boundsContains(obj, lx, ly) -> the name of the first bounding box in SLOT order (SkeletonBounds::update +
// containsPoint) containing the skeleton-space point, or nil
static Skeleton *checkSkeleton(lua_State *L, const char *fn) {
    lua_getfield(L, 1, "_skeleton");
    Skeleton *skeleton = ((SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton"))->skeleton;
    lua_pop(L, 1);
    if (!skeleton) luaL_error(L, "%s: removed skeleton", fn);
    return skeleton;
}

static int boundsContains(lua_State *L) {
    Skeleton *skeleton = checkSkeleton(L, "boundsContains");
    float x = (float)luaL_checknumber(L, 2), y = (float)luaL_checknumber(L, 3);
    SkeletonBounds bounds;
    bounds.update(*skeleton, true);
    BoundingBoxAttachment *box = bounds.containsPoint(x, y);
    if (box) lua_pushstring(L, box->getName().buffer()); else lua_pushnil(L);
    return 1;
}

// __probe.setSkeletonTransform(obj, x, y, scaleX, scaleY): the Spine skeleton's own x/y/scale, which the plugin keeps
// at 0/0/1/1 and does not expose to Lua; for the root-bone world-position formula and its scale-0 raise
static int setSkeletonTransform(lua_State *L) {
    Skeleton *skeleton = checkSkeleton(L, "setSkeletonTransform");
    skeleton->setX((float)luaL_checknumber(L, 2));
    skeleton->setY((float)luaL_checknumber(L, 3));
    skeleton->setScaleX((float)luaL_checknumber(L, 4));
    skeleton->setScaleY((float)luaL_checknumber(L, 5));
    return 0;
}

extern "C" int worldspace_native(lua_State *L) {
    const luaL_Reg fns[] = {{"boundsContains", boundsContains}, {"setSkeletonTransform", setSkeletonTransform},
                            {NULL, NULL}};
    luaL_register(L, "__probe", fns);
    lua_pop(L, 1);
    return 0;
}
