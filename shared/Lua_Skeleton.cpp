#include "Lua_Skeleton.h"
#include "Lua_Slot.h"
#include "Lua_Bone.h"
#include "Lua_IKConstraint.h"
#include "Lua_Physics.h"
#include "Lua_Track.h"
#include "Lua_Skin.h"
#include "Lua_TrackEntry.h"
#include "SpineRenderer.h"
#include <cmath>

static SpineSkeleton *luaL_getSkeletonUserdata(lua_State *L)
{
    if (!lua_istable(L, 1))
    {
        luaL_argerror(L, 1, "SpineSkeleton expected. If this is a function call, you might have used '.' instead of ':'");
        return 0;
    }

    lua_pushstring(L, "_skeleton");
    lua_rawget(L, 1);

    if (lua_isnil(L, -1))
    {
        luaL_argerror(L, 1, "SpineSkeleton expected, got table");
        return 0;
    }

    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    
    lua_pop(L, 1);

    // Solar2D strips a finalized display object's metatable and the next frame disposes the skeleton: only a
    // cached method can still reach it
    if (!lua_getmetatable(L, 1) || !skeletonUserdata->skeleton)
    {
        luaL_error(L, "Skeleton belongs to a removed skeleton");
    }
    lua_pop(L, 1);

    return skeletonUserdata;
}

// The keys a removed object still answers: Solar2D's EventDispatcher, which dispatches its "finalize", and the
// helpers its add/removeEventListener call through self (platform/resources/init.lua EventDispatcher and
// DisplayObject; _setHasListener is a display-object proxy key).
static bool isEventDispatcherKey(const char *key)
{
    static const char *const keys[] = {"addEventListener", "removeEventListener", "hasEventListener",
                                       "dispatchEvent", "respondsToEvent", "getOrCreateTable",
                                       "didRemoveListener", "_setHasListener"};
    for (const char *k : keys)
    {
        if (strcmp(key, k) == 0) return true;
    }
    return false;
}

// Pushes the display group's value for key (argument 2) of the object (argument 1).
static void groupIndex(lua_State *L, SpineSkeleton *skeletonUserdata)
{
    skeletonUserdata->groupmt__index->pushTable(L);
    lua_pushvalue(L, 1);
    lua_pushvalue(L, 2);
    lua_call(L, 2, 1);
}

void SpineSkeleton::onEffectUpdated(const char *key, lua_State *L_in, int valueIndex)
{
    bool isNameKey = strcmp(key, "name") == 0;

    for (auto &meshData : meshes)
    {
        if (meshData.mesh.isValid())
        {
            meshData.mesh.pushTable(L_in);
            lua_pushstring(L_in, "fill");
            lua_gettable(L_in, -2); // get the fill table
            
            if (isNameKey)
            {
                // key == "name" then update the effect on all meshes
                lua_pushstring(L_in, "effect");
                lua_pushvalue(L_in, valueIndex);
                lua_settable(L_in, -3);
            } 
            else
            {
                lua_pushstring(L_in, "effect");
                lua_gettable(L_in, -2); // get the effect table

                if (lua_isnil(L_in, -1))
                {
                    // set effect name
                    lua_pop(L_in, 1); // pop nil
                    lua_pushstring(L_in, "effect");
                    lua_pushstring(L_in, effectData->name().c_str());
                    lua_settable(L_in, -3);
                    // get the effect table again
                    lua_pushstring(L_in, "effect");
                    lua_gettable(L_in, -2); // get the effect table
                }

                // update the specific property
                lua_pushstring(L_in, key);
                lua_pushvalue(L_in, valueIndex);
                lua_settable(L_in, -3);
                lua_pop(L_in, 1); // pop effect table
            }
            lua_pop(L_in, 1); // pop fill table
            lua_pop(L_in, 1); // pop mesh table
        }
    }
}

static int getArgCount(lua_State *L)
{
    int argCount = lua_gettop(L);
    int nonNilArgCount = 1;
    for (int i = 2; i <= argCount; i++)
    {
        if (!lua_isnil(L, i))
        {
            nonNilArgCount++;
        }
    }
    return nonNilArgCount;
}

static int checkTrackIndex(lua_State *L, int argIndex)
{
    int trackIndex = luaL_checkint(L, argIndex) - 1;
    if (trackIndex < 0)
    {
        luaL_argerror(L, argIndex, "trackIndex must be >= 1");
    }
    return trackIndex;
}

static int skeleton_index(lua_State *L)
{
    const char *key = luaL_checkstring(L, 2);

    lua_pushstring(L, "_skeleton");
    lua_rawget(L, 1);

    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    if (!skeletonUserdata->skeleton || skeletonUserdata->disposeRequested)
    {
        // removed: only the EventDispatcher keys resolve (so `if obj.removeSelf then` skips it), numChildren is nil
        if (!isEventDispatcherKey(key)) return 0;
        groupIndex(L, skeletonUserdata);
        return 1;
    }

    if (strcmp(key, "isActive") == 0)
    {
        lua_pushboolean(L, skeletonUserdata->state->getTracks().size() > 0);
        return 1;
    } 
    else if (strcmp(key, "timeScale") == 0)
    {
        lua_pushnumber(L, skeletonUserdata->state->getTimeScale());
        return 1;
    }
    else if (strcmp(key, "physicsTimeScale") == 0)
    {
        lua_pushnumber(L, skeletonUserdata->physicsTimeScale);
        return 1;
    }
    else if (strcmp(key, "slots") == 0)
    {
        Skeleton *skeleton = skeletonUserdata->skeleton;
        Vector<Slot *> &slots = skeleton->getSlots();
        size_t n = slots.size();
        lua_createtable(L, static_cast<int>(n), 0);

        for (size_t i = 0; i < n; i++)
        {
            LuaSlot *slotUserdata = (LuaSlot *)lua_newuserdata(L, sizeof(LuaSlot));
            new (slotUserdata) LuaSlot(L, slots[i], skeletonUserdata->dataOwner, skeletonUserdata->alive);

            lua_rawseti(L, -2, static_cast<int>(i + 1));
        }

        return 1;
    }
    else if (strcmp(key, "bones") == 0)
    {
        Skeleton *skeleton = skeletonUserdata->skeleton;
        Vector<Bone *> &bones = skeleton->getBones();
        size_t n = bones.size();
        lua_createtable(L, static_cast<int>(n), 0);

        for (size_t i = 0; i < n; i++)
        {
            LuaBone *boneUserdata = (LuaBone *)lua_newuserdata(L, sizeof(LuaBone));
            new (boneUserdata) LuaBone(L, bones[i], skeletonUserdata->alive);

            lua_rawseti(L, -2, static_cast<int>(i + 1));
        }

        return 1;
    } else if (strcmp(key, "ikConstraints") == 0)
    {
        Skeleton *skeleton = skeletonUserdata->skeleton;
        lua_newtable(L);
        int i = 0;

        spc::forEachIk(skeleton, [&](IkConstraint *ikConstraint) {
            LuaIKConstraint *ikConstraintUserdata = (LuaIKConstraint *)lua_newuserdata(L, sizeof(LuaIKConstraint));
            new (ikConstraintUserdata) LuaIKConstraint(L, ikConstraint, skeletonUserdata->skeleton, skeletonUserdata->alive);

            lua_rawseti(L, -2, ++i);
        });

        return 1;
    } else if (strcmp(key, "physics") == 0)
    {
        Vector<PhysicsConstraint*> PhysicsConstraints = skeletonUserdata->skeleton->getPhysicsConstraints();

        if (PhysicsConstraints.size() == 0)
        {
            lua_pushnil(L);
            return 1;
        }

        LuaPhysics *physicsUserdata = (LuaPhysics *)lua_newuserdata(L, sizeof(LuaPhysics));
        new (physicsUserdata) LuaPhysics(L, PhysicsConstraints, skeletonUserdata->alive);

        return 1;
    }
    else if (strcmp(key, "tracks") == 0)
    {
        Vector<TrackEntry *> &tracks = skeletonUserdata->state->getTracks();
        
        LuaTrack *entryUserdata = (LuaTrack *)lua_newuserdata(L, sizeof(LuaTrack));
        new (entryUserdata) LuaTrack(L, tracks, skeletonUserdata->alive);
        
        return 1;
    }
    else if (strcmp(key, "fill") == 0)
    {
        LuaFill *fillUserdata = (LuaFill *)lua_newuserdata(L, sizeof(LuaFill));
        new (fillUserdata) LuaFill(L, skeletonUserdata, skeletonUserdata->alive);
        return 1;
    }
    else if (strcmp(key, "numChildren") == 0)
    {
        return 0;
    }

    // Fallback to methods
    lua_getmetatable(L, 1);
    lua_pushvalue(L, 2);
    lua_rawget(L, -2);

    if (!lua_isnil(L, -1))
    {
        return 1;
    }

    skeletonUserdata->groupmt__index->pushTable(L);
    lua_pushvalue(L, 1);
    lua_pushvalue(L, 2);
    lua_call(L, 2, 1);

    if (!lua_isnil(L, -1))
    {
        return 1;
    }

    return 0;
}

static int groupNewindex(lua_State *L, SpineSkeleton *skeletonUserdata)
{
    skeletonUserdata->groupmt__newindex->pushTable(L);
    lua_pushvalue(L, 1);
    lua_pushvalue(L, 2);
    lua_pushvalue(L, 3);
    lua_call(L, 3, 0);
    return 0;
}

static int skeleton_newindex(lua_State *L)
{
    lua_pushstring(L, "_skeleton");
    lua_rawget(L, 1);

    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    const char *key = luaL_checkstring(L, 2);

    if (!skeletonUserdata->skeleton || skeletonUserdata->disposeRequested)
    {
        return groupNewindex(L, skeletonUserdata); // removed: the display group takes every key
    }

    if (strcmp(key, "timeScale") == 0)
    {
        float timeScale = luaL_checknumber(L, 3);
        skeletonUserdata->state->setTimeScale(timeScale);
        return 0;
    }

    if (strcmp(key, "physicsTimeScale") == 0)
    {
        float physicsTimeScale = luaL_checknumber(L, 3); // checked as float: a finite double can overflow it
        if (!std::isfinite(physicsTimeScale) || physicsTimeScale < 0)
            return luaL_error(L, "physicsTimeScale must be a finite number >= 0");
        skeletonUserdata->physicsTimeScale = physicsTimeScale;
        return 0;
    }

    skeletonUserdata->groupmt__newindex->pushTable(L);
    lua_pushvalue(L, 1);
    lua_pushvalue(L, 2);
    lua_pushvalue(L, 3);
    lua_call(L, 3, 0);

    return 0;
}

static int skeleton_gc(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, 1, "SpineSkeleton");

    skeletonUserdata->~SpineSkeleton(); // dispose() is idempotent; __gc runs once per userdata

    return 0;
}

// The SpineSkeleton userdata at index, or NULL.
static SpineSkeleton *toSkeletonUserdata(lua_State *L, int index)
{
    void *p = lua_touserdata(L, index);
    if (!p || !lua_getmetatable(L, index)) return NULL;
    luaL_getmetatable(L, "SpineSkeleton");
    bool isSkeleton = lua_rawequal(L, -1, -2) != 0;
    lua_pop(L, 2);
    return isSkeleton ? (SpineSkeleton *)p : NULL;
}

// Next-frame dispose queue: registry { [SpineSkeleton userdata] = display object }, drained by one Runtime hook.
static int disposeQueueRef = LUA_NOREF;
static int disposeHookRef = LUA_NOREF;

void resetDisposeQueue()
{
    disposeQueueRef = LUA_NOREF;
    disposeHookRef = LUA_NOREF;
}

static void runtimeHookCall(lua_State *L, const char *method, int nresults)
{
    lua_getglobal(L, "Runtime");
    lua_getfield(L, -1, method);
    lua_insert(L, -2);
    lua_pushstring(L, "enterFrame");
    lua_rawgeti(L, LUA_REGISTRYINDEX, disposeHookRef);
    lua_call(L, 3, nresults);
}

// Runtime "enterFrame" hook: frees the skeletons finalized since it was armed. It only disposes, never updates,
// applies, draws or dispatches events (L16).
static int disposeFinalized(lua_State *L)
{
    runtimeHookCall(L, "removeEventListener", 0);

    lua_rawgeti(L, LUA_REGISTRYINDEX, disposeQueueRef);
    luaL_unref(L, LUA_REGISTRYINDEX, disposeQueueRef);
    disposeQueueRef = LUA_NOREF;
    if (!lua_istable(L, -1)) return 0;
    int queue = lua_gettop(L);

    lua_pushnil(L);
    while (lua_next(L, queue) != 0)
    {
        int object = lua_gettop(L);
        SpineSkeleton *skeletonUserdata = toSkeletonUserdata(L, object - 1);
        // Solar2D's RestoreTable strips the metatable after a real finalize: one still set was user-dispatched
        if (skeletonUserdata && !lua_getmetatable(L, object))
        {
            skeletonUserdata->requestDispose();
        }
        lua_settop(L, object - 1);
    }
    return 0;
}

// Arms the hook unless Runtime already holds it (an app may have cleared every Runtime listener). Run by lua_cpcall.
static int armDisposeHook(lua_State *L)
{
    if (disposeHookRef == LUA_NOREF)
    {
        lua_pushcfunction(L, disposeFinalized);
        disposeHookRef = luaL_ref(L, LUA_REGISTRYINDEX);
    }
    runtimeHookCall(L, "hasEventListener", 1);
    if (!lua_toboolean(L, -1)) runtimeHookCall(L, "addEventListener", 0);
    return 0;
}

// Solar2D "finalize" listener, registered by create(): the display object was removed, directly or with its
// parent. User finalize listeners that follow still reach the object and its wrappers, which raise once RestoreTable
// strips the metatable. The skeleton is queued and freed by the next-frame hook.
int spine_onFinalize(lua_State *L)
{
    if (!lua_istable(L, 1)) return 0;
    lua_getfield(L, 1, "target");
    if (!lua_istable(L, -1)) return 0;
    int target = lua_gettop(L);

    lua_pushstring(L, "_skeleton");
    lua_rawget(L, target);
    SpineSkeleton *skeletonUserdata = toSkeletonUserdata(L, -1);
    if (!skeletonUserdata || !skeletonUserdata->skeleton) return 0;

    // never raise here: without a Runtime to run the hook, free the skeleton now
    if (lua_cpcall(L, armDisposeHook, NULL) != 0)
    {
        skeletonUserdata->requestDispose();
        return 0;
    }

    if (disposeQueueRef == LUA_NOREF)
    {
        lua_newtable(L);
        disposeQueueRef = luaL_ref(L, LUA_REGISTRYINDEX);
    }
    lua_rawgeti(L, LUA_REGISTRYINDEX, disposeQueueRef);
    lua_pushvalue(L, -2);
    lua_pushvalue(L, target);
    lua_rawset(L, -3);
    return 0;
}




// skeleton:getSkins()
static int getSkins(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    SkeletonData *skeletonData = skeletonUserdata->skeletonData;
    Vector<Skin *> &skins = skeletonData->getSkins();
    size_t n = skins.size();
    lua_createtable(L, static_cast<int>(n), 0);

    for (size_t i = 0; i < n; i++)
    {
        lua_pushstring(L, skins[i]->getName().buffer());
        lua_rawseti(L, -2, static_cast<int>(i + 1));
    }

    return 1;
}

// skeleton:setSkin(skinNameOrObject)
static int setSkin(lua_State *L)
{
    if (lua_gettop(L) < 2 || lua_gettop(L) > 3)
    {
        luaL_error(L, "Expected self, skinNameOrObject [, resetSlots]");
        return 0;
    }

    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    bool resetSlots = true;
    if (!lua_isnoneornil(L, 3)) {
        luaL_checktype(L, 3, LUA_TBOOLEAN);
        resetSlots = lua_toboolean(L, 3);
    }

    Skeleton *skeleton = skeletonUserdata->skeleton;
    SkeletonData *skeletonData = skeletonUserdata->skeletonData;
    Skin *skin = nullptr;

    // Check if argument is a string (skin name) or Skin object
    if (lua_isstring(L, 2))
    {
        const char *skinName = lua_tostring(L, 2);
        if (!skinName)
        {
            luaL_argerror(L, 2, "Skin name is required");
            return 0;
        }

        skin = skeletonData->findSkin(skinName);
        if (!skin)
        {
            luaL_error(L, "Skin not found: %s", skinName);
            return 0;
        }
    }
    else if (lua_isuserdata(L, 2))
    {
        // Check if it's a Skin object
        LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 2, "SpineSkin");
        if (!skinUserdata || !skinUserdata->skin)
        {
            luaL_argerror(L, 2, "Invalid Skin object");
            return 0;
        }
        if (skinUserdata->skeletonData != skeletonData)
            return luaL_argerror(L, 2, "Skin belongs to different skeleton data");
        skin = skinUserdata->skin;
    }
    else
    {
        luaL_argerror(L, 2, "Expected skin name (string) or Skin object");
        return 0;
    }

    if (skeleton->getSkin() == skin) skeleton->updateCache();
    else skeleton->setSkin(skin);
    if (resetSlots) spc::setSlotsToSetupPose(skeleton);
    skeletonUserdata->appliedSkinOwner = getLuaSkinOwner(skin);

    return 0;
}

// skeleton:createSkin(name)
static int createSkin(lua_State *L)
{
    if (lua_gettop(L) != 2)
    {
        luaL_error(L, "Expected 2 arguments: self, skinName");
        return 0;
    }

    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    const char *skinName = luaL_checkstring(L, 2);
    if (!skinName || strlen(skinName) == 0)
    {
        luaL_argerror(L, 2, "Skin name is required");
        return 0;
    }

    // Create new Skin
    Skin *newSkin = new Skin(skinName);

    // Create LuaSkin userdata and return it
    LuaSkin *skinUserdata = (LuaSkin *)lua_newuserdata(L, sizeof(LuaSkin));
    new (skinUserdata) LuaSkin(L, newSkin, skeletonUserdata->skeletonData, true, skeletonUserdata->dataOwner); // ownsMemory = true

    return 1;
}

// skeleton:getSkin()
static int getSkin(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    Skin *skin = skeletonUserdata->skeleton->getSkin();
    if (!skin)
    {
        lua_pushnil(L);
        return 1;
    }

    // Create LuaSkin userdata and return it
    LuaSkin *skinUserdata = (LuaSkin *)lua_newuserdata(L, sizeof(LuaSkin));
    new (skinUserdata) LuaSkin(L, skin, skeletonUserdata->skeletonData, false, skeletonUserdata->dataOwner); // ownsMemory = false (skin belongs to skeleton)

    return 1;
}

// skeleton:registerSkin(skinObject)
// Adds a custom skin to the SkeletonData so it can be used by name
static int registerSkin(lua_State *L)
{
    if (lua_gettop(L) != 2)
    {
        luaL_error(L, "Expected 2 arguments: self, skinObject");
        return 0;
    }

    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    // Check if argument is a Skin object
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 2, "SpineSkin");
    if (!skinUserdata || !skinUserdata->skin)
    {
        luaL_argerror(L, 2, "Invalid Skin object");
        return 0;
    }

    if (skinUserdata->skeletonData != skeletonUserdata->skeletonData)
        return luaL_argerror(L, 2, "Skin belongs to different skeleton data");

    // Add skin to SkeletonData's skins vector
    SkeletonData *skeletonData = skeletonUserdata->skeletonData;
    Vector<Skin *> &skins = skeletonData->getSkins();
    
    // Check if skin with this name already exists
    const String &skinName = skinUserdata->skin->getName();
    bool found = false;
    for (size_t i = 0; i < skins.size(); i++)
    {
        if (skins[i]->getName() == skinName)
        {
            if (skins[i] != skinUserdata->skin)
                return luaL_error(L, "A different skin is already registered as %s", skinName.buffer());
            found = true;
            break;
        }
    }

    if (!found)
    {
        skins.add(skinUserdata->skin);
        // Transfer ownership to SkeletonData
        skinUserdata->owner->ownsMemory = false;
    }

    return 0;
}




// skeleton:setToSetupPose()
static int setToSetupPose(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    spc::setToSetupPose(skeletonUserdata->skeleton);

    return 0;
}

// skeleton:setBonesToSetupPose()
static int setBonesToSetupPose(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    spc::setBonesToSetupPose(skeletonUserdata->skeleton);

    return 0;
}

// skeleton:setSlotsToSetupPose()
static int setSlotsToSetupPose(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    spc::setSlotsToSetupPose(skeletonUserdata->skeleton);

    return 0;
}




// skeleton:setAnimation(trackIndex, animationName, loop)
static int setAnimation(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    int trackIndex = checkTrackIndex(L, 2);
    const char *animationName = luaL_checkstring(L, 3);
    bool loop = lua_toboolean(L, 4);

    Animation *animation = skeletonUserdata->skeletonData->findAnimation(animationName);
    if (!animation)
    {
        lua_pushboolean(L, false);
        return 1;
    }
    
    SkeletonCallGuard guard(skeletonUserdata);
    TrackEntry *entry = spc::setAnimation(skeletonUserdata->state, trackIndex, animation, loop);
    if (!entry)
    {
        lua_pushboolean(L, false);
        return 1;
    }
    if (skeletonUserdata->disposeRequested) return 0; // a listener removed the object: no entry to hand out
    guard.release(); // no callback runs below, and the wrapper's allocation can raise

    LuaTrackEntry *entryUserdata = (LuaTrackEntry *)lua_newuserdata(L, sizeof(LuaTrackEntry));
    new (entryUserdata) LuaTrackEntry(L, entry, skeletonUserdata->alive);

    return 1;
}

// skeleton:addAnimation(trackIndex, animationName, loop, delay)
static int addAnimation(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    int trackIndex = checkTrackIndex(L, 2);
    const char *animationName = luaL_checkstring(L, 3);
    bool loop = lua_toboolean(L, 4);
    float delay = luaL_checknumber(L, 5) / 1000;

    Animation *animation = skeletonUserdata->skeletonData->findAnimation(animationName);
    if (!animation)
    {
        lua_pushboolean(L, false);
        return 1;
    }
    
    SkeletonCallGuard guard(skeletonUserdata);
    TrackEntry *entry = spc::addAnimation(skeletonUserdata->state, trackIndex, animation, loop, delay);
    if (!entry)
    {
        lua_pushboolean(L, false);
        return 1;
    }
    if (skeletonUserdata->disposeRequested) return 0; // a listener removed the object: no entry to hand out
    guard.release(); // no callback runs below, and the wrapper's allocation can raise

    LuaTrackEntry *entryUserdata = (LuaTrackEntry *)lua_newuserdata(L, sizeof(LuaTrackEntry));
    new (entryUserdata) LuaTrackEntry(L, entry, skeletonUserdata->alive);

    return 1;
}

// skeleton:addAnimationAt(trackIndex, animationName, loop, startTimeMs)
static int addAnimationAt(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    int trackIndex = checkTrackIndex(L, 2);
    const char *animationName = luaL_checkstring(L, 3);
    bool loop = lua_toboolean(L, 4);
    float startTime = luaL_checknumber(L, 5) / 1000;

    Animation *animation = skeletonUserdata->skeletonData->findAnimation(animationName);
    if (!animation)
    {
        lua_pushboolean(L, false);
        return 1;
    }

    SkeletonCallGuard guard(skeletonUserdata);
    float delay = startTime;
    TrackEntry *current = spc::current(skeletonUserdata->state, trackIndex);
    if (!current && startTime > 0)
    {
        // Keep the first queued animation delayed even on an empty track.
        // Without this, addAnimation sets it as current immediately.
        skeletonUserdata->state->setEmptyAnimation(trackIndex, 0);
        current = spc::current(skeletonUserdata->state, trackIndex);
    }

    if (current)
    {
        // addAnimation delay is relative to the previous queued entry's start.
        // Convert absolute timeline time to queue-relative delay by accumulating
        // the start time of the current queue tail.
        float tailStartTime = 0;
        TrackEntry *tail = current;
        while (tail->getNext() != NULL)
        {
            tail = tail->getNext();
            tailStartTime += tail->getDelay();
        }
        delay = startTime - tailStartTime;
    }
    if (delay < 0)
    {
        delay = 0;
    }

    TrackEntry *entry = spc::addAnimation(skeletonUserdata->state, trackIndex, animation, loop, delay);
    if (!entry)
    {
        lua_pushboolean(L, false);
        return 1;
    }
    if (skeletonUserdata->disposeRequested) return 0; // a listener removed the object: no entry to hand out
    guard.release(); // no callback runs below, and the wrapper's allocation can raise

    LuaTrackEntry *entryUserdata = (LuaTrackEntry *)lua_newuserdata(L, sizeof(LuaTrackEntry));
    new (entryUserdata) LuaTrackEntry(L, entry, skeletonUserdata->alive);

    return 1;
}

// skeleton:setEmptyAnimation(trackIndex, mixDuration)
static int setEmptyAnimation(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    int trackIndex = checkTrackIndex(L, 2);
    float mixDuration = luaL_checknumber(L, 3) / 1000;

    SkeletonCallGuard guard(skeletonUserdata);
    skeletonUserdata->state->setEmptyAnimation(trackIndex, mixDuration);
    return 0;
}

// skeleton:addEmptyAnimation(trackIndex, mixDuration, delay)
static int addEmptyAnimation(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    int trackIndex = checkTrackIndex(L, 2);
    float mixDuration = luaL_checknumber(L, 3) / 1000;
    float delay = luaL_checknumber(L, 4) / 1000;

    SkeletonCallGuard guard(skeletonUserdata);
    skeletonUserdata->state->addEmptyAnimation(trackIndex, mixDuration, delay);
    return 0;
}

// skeleton:setEmptyAnimations(mixDuration)
static int setEmptyAnimations(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    float mixDuration = luaL_checknumber(L, 2) / 1000;
    SkeletonCallGuard guard(skeletonUserdata);
    skeletonUserdata->state->setEmptyAnimations(mixDuration);
    return 0;
}

// skeleton:setListener(listenerOrNil)
static int setListener(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    if (lua_isnil(L, 2))
    {
        skeletonUserdata->state->setListener((AnimationStateListenerObject *)NULL);
        if (skeletonUserdata->stateListener)
        {
            delete skeletonUserdata->stateListener;
            skeletonUserdata->stateListener = nullptr;
        }
        return 0;
    }

    luaL_checktype(L, 2, LUA_TFUNCTION);
    lua_pushvalue(L, 2);
    int listenerRef = luaL_ref(L, LUA_REGISTRYINDEX);

    if (skeletonUserdata->stateListener)
    {
        delete skeletonUserdata->stateListener;
        skeletonUserdata->stateListener = nullptr;
    }

    LuaAnimationStateListener *stateListener = new LuaAnimationStateListener(L, &skeletonUserdata->luaSelf, listenerRef);
    skeletonUserdata->stateListener = stateListener;
    skeletonUserdata->state->setListener(stateListener);
    return 0;
}

// skeleton:findAnimation(animationName)
static int findAnimation(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    const char *animationName = luaL_checkstring(L, 2);

    Animation *animation = skeletonUserdata->skeletonData->findAnimation(animationName);

    lua_pushboolean(L, animation != nullptr);

    return 1;
}

// skeleton:getCurrentAnimation(trackIndex)
static int getCurrentAnimation(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    // optional trackIndex (defaults to 1)
    int trackIndex = luaL_optint(L, 2, 1) - 1;
    if (trackIndex < 0)
    {
        luaL_argerror(L, 2, "trackIndex must be >= 1");
    }

    TrackEntry *entry = spc::current(skeletonUserdata->state, trackIndex);
    if (!entry)
    {
        lua_pushnil(L);
        return 1;
    }

    const char *animationName = spc::anim(*entry).getName().buffer();
    lua_pushstring(L, animationName);

    return 1;
}

// skeleton:getTrackEntry(trackIndex)
static int getTrackEntry(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    int trackIndex = checkTrackIndex(L, 2);
    TrackEntry *entry = spc::current(skeletonUserdata->state, trackIndex);
    if (!entry)
    {
        lua_pushnil(L);
        return 1;
    }

    LuaTrackEntry *entryUserdata = (LuaTrackEntry *)lua_newuserdata(L, sizeof(LuaTrackEntry));
    new (entryUserdata) LuaTrackEntry(L, entry, skeletonUserdata->alive);

    return 1;
}

// skeleton:getAnimations()
static int getAnimations(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    SkeletonData *skeletonData = skeletonUserdata->skeletonData;
    Vector<Animation *> &animations = skeletonData->getAnimations();
    size_t n = animations.size();
    lua_createtable(L, static_cast<int>(n), 0);

    for (size_t i = 0; i < n; i++)
    {
        lua_pushstring(L, animations[i]->getName().buffer());
        lua_rawseti(L, -2, static_cast<int>(i + 1));
    }

    return 1;
}



// skeleton:setDefaultMix(mix)
static int setDefaultMix(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    float mix = luaL_checknumber(L, 2);

    mix = mix / 1000;

    skeletonUserdata->stateData->setDefaultMix(mix);

    return 0;
}

// skeleton:setMix(from, to, mix)
static int setMix(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    const char *from = luaL_checkstring(L, 2);
    const char *to = luaL_checkstring(L, 3);
    float mix = luaL_checknumber(L, 4);

    Animation *fromAnimation = skeletonUserdata->skeletonData->findAnimation(from);
    if (!fromAnimation)
    {
        luaL_error(L, "Animation not found: %s", from);
        return 0;
    }

    Animation *toAnimation = skeletonUserdata->skeletonData->findAnimation(to);
    if (!toAnimation)
    {
        luaL_error(L, "Animation not found: %s", to);
        return 0;
    }

    spc::setMix(skeletonUserdata->stateData, fromAnimation, toAnimation, mix / 1000);
    return 0;
}





// skeleton:updateState(deltaTime)
static int updateState(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    float deltaTime = luaL_checknumber(L, 2);
    deltaTime /= 1000;
    SkeletonCallGuard guard(skeletonUserdata);

    // Animation work only when a track exists, but always advance the skeleton clock: it is what
    // Physics_Update steps on, so a skeleton with physics and no animation never simulated (render-5).
    if (skeletonUserdata->state->getTracks().size() > 0)
    {
        skeletonUserdata->state->update(deltaTime);
        if (skeletonUserdata->disposeRequested) return 0;
        skeletonUserdata->state->apply(*skeletonUserdata->skeleton);
        if (skeletonUserdata->disposeRequested) return 0;
    }
    skeletonUserdata->skeleton->update(deltaTime * skeletonUserdata->physicsTimeScale);

    return 0;
}


static bool isObjectValid(lua_State *L)
{
    // check -1 has a parent
    lua_pushstring(L, "parent");
    lua_gettable(L, -2);
    bool valid = !lua_isnil(L, -1);
    lua_pop(L, 1);

    return valid;
}

static std::vector<int> checkInjections(lua_State *L, SpineSkeleton *skeletonUserdata)
{
    std::vector<InjectedObject> &injections = skeletonUserdata->injections;
    std::vector<int> injectionSlotIndexes = {};
    for (auto it = injections.begin(); it != injections.end();)
    {
        it->updated = false;
        it->pushObject(L);
        if (isObjectValid(L)) {
            injectionSlotIndexes.emplace_back(it->getSlotIndex());
            ++it;
        }
        else {
            it = injections.erase(it);
        }

        lua_pop(L, 1);
    }

    return injectionSlotIndexes;
}

static void skeletonRender(lua_State *L, SpineSkeleton *skeletonUserdata)
{
    Skeleton *skeleton = skeletonUserdata->skeleton;
    SkeletonRenderer skeletonRenderer;

    RenderCommand *command;

    auto &meshes = skeletonUserdata->meshes;

    for (auto &meshData : meshes)
    {
        meshData.used = false;
    }

    if (skeletonUserdata->splitData.isSplitted())
    {
        auto slotIndices = skeletonUserdata->splitData.getSlotIndices();
        auto commandsInSplit = skeletonUserdata->splitData.commandsInSplit;
        auto commandsNotInSplit = skeletonUserdata->splitData.commandsNotInSplit;
        spc::CommandPair commands = spc::renderSplit(skeletonRenderer, *skeleton, checkInjections(L, skeletonUserdata), slotIndices, commandsInSplit, commandsNotInSplit);
        renderCommands(L, skeletonUserdata, commands.first, meshes, 1);
        if (skeletonUserdata->disposeRequested) return;

        skeletonUserdata->splitData.pushGroup(L);
        renderCommands(L, skeletonUserdata, commands.second, meshes, 2);
        if (skeletonUserdata->disposeRequested) return;
        
        lua_remove(L, 2);
    }
    else {
        command = skeletonRenderer.render(*skeleton, checkInjections(L, skeletonUserdata));

        renderCommands(L, skeletonUserdata, command, meshes, 1);
        if (skeletonUserdata->disposeRequested) return;
    }

    for (int index = static_cast<int>(meshes.size()) - 1; index >= 0; index--)
    {
        MeshData &meshCandidate = meshes[index];

        if (!meshCandidate.used)
        {
            if (meshCandidate.mesh.isValid())
            {
                LuaTableHolder &mesh = meshCandidate.mesh;
                engine_removeMesh(L, &mesh);
            }
            meshes.removeMesh(index);
        }
    }

    lua_pop(L, -1);
}

// skeletonRender as a Lua C function over draw's own arguments (the skeleton as upvalue), so draw can run it through
// its guard: the injection listeners it calls may raise.
static int skeletonRenderCall(lua_State *L)
{
    skeletonRender(L, (SpineSkeleton *)lua_touserdata(L, lua_upvalueindex(1)));
    return 0;
}

// skeleton:draw()
static int skeletonDraw(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    SkeletonCallGuard guard(skeletonUserdata);
    // updateWorldTransform already skips inactive constraints; gating on constraint #1 froze all physics
    // whenever that one was skin-required and inactive (render-4).
    skeletonUserdata->skeleton->updateWorldTransform(Physics_Update);

    int nargs = lua_gettop(L);
    lua_pushlightuserdata(L, skeletonUserdata);
    lua_pushcclosure(L, skeletonRenderCall, 1);
    lua_insert(L, 1);
    guard.call(L, nargs, 0);

    return 0;
}


// skeleton:setAttachment(slotName, attachmentName)
static int setAttachment(lua_State *L) {
    if (lua_gettop(L) != 3) {
        luaL_error(L, "Expected 3 arguments: self, slotName, attachmentName");
        return 0;
    }

    const char *slotName = luaL_checkstring(L, 2);
    const char *attachmentName = luaL_optstring(L, 3, nullptr);

    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    Slot* slot = skeletonUserdata->skeleton->findSlot(slotName);
    if (!slot) {
        luaL_error(L, "Slot not found: %s", slotName);
        return 0;
    }

    Attachment* attachment = nullptr;
    if (attachmentName) {
        attachment = skeletonUserdata->skeleton->getAttachment(slot->getData().getIndex(), attachmentName);
        if (!attachment) {
            luaL_error(L, "Attachment not found: %s", attachmentName);
            return 0;
        }
    }

    spc::pose(*slot).setAttachment(attachment);

    return 0;
}


// skeleton:findSlot(slotName) : bool
static int findSlot(lua_State *L)
{
    SpineSkeleton* skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata) {
        return 0;
    }

    const char* slotName = luaL_checkstring(L, 2);

    Slot* slot = skeletonUserdata->skeleton->findSlot(slotName);
    lua_pushboolean(L, slot != nullptr);

    return 1;
}

// skeleton:getSlot(slotName) : Slot
static int getSlot(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    const char *slotName = luaL_checkstring(L, 2);

    Slot *slot = skeletonUserdata->skeleton->findSlot(slotName);

    if (!slot)
    {
        luaL_error(L, "Slot not found: %s", slotName);
        return 0;
    }

    LuaSlot *slotUserdata = (LuaSlot *)lua_newuserdata(L, sizeof(LuaSlot));
    new (slotUserdata) LuaSlot(L, slot, skeletonUserdata->dataOwner, skeletonUserdata->alive);

    return 1;
}


// skeleton:getSlotNames() : Array<string>
static int getSlotNames(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    Skeleton *skeleton = skeletonUserdata->skeleton;
    Vector<Slot *> &slots = skeleton->getSlots();
    size_t n = slots.size();
    lua_createtable(L, static_cast<int>(n), 0);

    for (size_t i = 0; i < n; i++)
    {
        lua_pushstring(L, slots[i]->getData().getName().buffer());
        lua_rawseti(L, -2, static_cast<int>(i + 1));
    }

    return 1;
}

// skeleton:getIKConstraint(ikConstraintName) : LuaIKConstraint
static int getIKConstraint(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    const char *ikConstraintName = luaL_checkstring(L, 2);

    Skeleton *skeleton = skeletonUserdata->skeleton;

    IkConstraint *ikConstraint = spc::findIk(skeleton, ikConstraintName);

    if (!ikConstraint)
    {
        luaL_error(L, "IKConstraint not found: %s", ikConstraintName);
        return 0;
    }

    LuaIKConstraint *ikConstraintUserdata = (LuaIKConstraint *)lua_newuserdata(L, sizeof(LuaIKConstraint));
    new (ikConstraintUserdata) LuaIKConstraint(L, ikConstraint, skeletonUserdata->skeleton, skeletonUserdata->alive);

    return 1;
}

// skeleton:getIKConstraint(ikConstraintName) : Array<string>
static int getIKConstraintNames(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    SkeletonData *skeletonData = skeletonUserdata->skeletonData;
    lua_newtable(L);
    int i = 0;

    spc::forEachIkData(skeletonData, [&](ConstraintData *ikConstraint) {
        lua_pushstring(L, ikConstraint->getName().buffer());
        lua_rawseti(L, -2, ++i);
    });

    return 1;
}






// skeleton:getBounds()
static int getBounds(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    auto skeleton = skeletonUserdata->skeleton; 
    SkeletonBounds bounds;
    bounds.update(*skeleton, true);

    // using skeleton->getBounds
    float outX, outY, outWidth, outHeight;
    spc::getBounds(skeleton, outX, outY, outWidth, outHeight);

    lua_createtable(L, 0, 4);

    lua_pushnumber(L, outX);
    lua_setfield(L, -2, "xMin");

    lua_pushnumber(L, outY);
    lua_setfield(L, -2, "yMin");

    lua_pushnumber(L, outX + outWidth);
    lua_setfield(L, -2, "xMax");

    lua_pushnumber(L, outY + outHeight);
    lua_setfield(L, -2, "yMax");

    return 1;
}

// skeleton:getSize()
static int getSize(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    auto skeleton = skeletonUserdata->skeleton;
    SkeletonBounds bounds;
    bounds.update(*skeleton, true);

    // using skeleton->getBounds
    float outX, outY, outWidth, outHeight;
    spc::getBounds(skeleton, outX, outY, outWidth, outHeight);

    lua_createtable(L, 0, 4);

    lua_pushnumber(L, outX);
    lua_setfield(L, -2, "offsetX");

    lua_pushnumber(L, -outY);
    lua_setfield(L, -2, "offsetY");

    lua_pushnumber(L, outWidth);
    lua_setfield(L, -2, "width");

    lua_pushnumber(L, outHeight);
    lua_setfield(L, -2, "height");

    return 1;
}

// skeleton:setFillColor(r, g, b, a)
static int setFillColor(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    double r, g, b, a;
    int nonNilArgCount = getArgCount(L);

    switch (nonNilArgCount)
    {
    case 1:
        luaL_argerror(L, 2, "number expected, got nil");
        return 0;
    case 2:
        r = luaL_checknumber(L, 2);
        g = r;
        b = r;
        a = 1;
        break;
    case 3:
        r = luaL_checknumber(L, 2);
        g = r;
        b = r;
        a = luaL_checknumber(L, 3);
        break;
    case 4:
        r = luaL_checknumber(L, 2);
        g = luaL_checknumber(L, 3);
        b = luaL_checknumber(L, 4);
        a = 1;
        break;
    default:
        r = luaL_checknumber(L, 2);
        g = luaL_checknumber(L, 3);
        b = luaL_checknumber(L, 4);
        a = luaL_checknumber(L, 5);
        break;
    }

    skeletonUserdata->skeleton->getColor().set(r, g, b, a);

    return 0;
}






static int getDrawOrder(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    Skeleton *skeleton = skeletonUserdata->skeleton;
    Vector<Slot *> &drawOrder = spc::drawOrder(skeleton);
    size_t n = drawOrder.size();
    lua_createtable(L, static_cast<int>(n), 0);

    for (size_t i = 0; i < n; i++)
    {
        lua_pushstring(L, drawOrder[i]->getData().getName().buffer());
        lua_rawseti(L, -2, static_cast<int>(i + 1));
    }

    return 1;
}

// skeleton:inject(slotName, object, [listener])
static int injectObject(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    if (!lua_istable(L, 2))
    {
        luaL_argerror(L, 3, "Expected displayObject");
        return 0;
    }

    // Validate before ejecting, inserting or taking the LuaTableHolder: luaL_error longjmps over its destructor.
    const char *slotName = luaL_checkstring(L, 3);
    Slot *slot = skeletonUserdata->skeleton->findSlot(slotName);
    if (!slot)
    {
        luaL_error(L, "Slot not found: %s", slotName);
        return 0;
    }

    // if object has been already injected, then eject first
    auto &injections = skeletonUserdata->injections;
    for (auto it = injections.begin(); it != injections.end();)
    {
        it->pushObject(L);
        if (lua_equal(L, -1, 2))
        {
            it = injections.erase(it);
            break;
        }
        else
        {
            ++it;
        }
        lua_pop(L, 1);
    }

    skeletonUserdata->groupInsert->pushTable(L);
    lua_pushvalue(L, 1);
    lua_pushvalue(L, 2);
    lua_call(L, 2, 0);

    LuaTableHolder object(L, 2);

    int slotIndex = slot->getData().getIndex();

    if (lua_isfunction(L, 4))
    {
        LuaTableHolder callback(L, 4);
        skeletonUserdata->injections.emplace_back(slotIndex, object, callback);
    }
    else
    {
        skeletonUserdata->injections.emplace_back(slotIndex, object);
    }

    return 0;
}

// skeleton:changeInjectionSlot(object, slotName)
static int changeInjectionSlot(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    const char *slotName = luaL_checkstring(L, 3);
    Slot *slot = skeletonUserdata->skeleton->findSlot(slotName);
    if (!slot)
    {
        luaL_error(L, "Slot not found: %s", slotName);
        return 0;
    }

    int slotIndex = slot->getData().getIndex();

    auto &injections = skeletonUserdata->injections;
    for (auto it = injections.begin(); it != injections.end();)
    {
        it->pushObject(L);
        if (lua_equal(L, -1, 2))
        {
            it->setSlotIndex(slotIndex);
            break;
        }
        else
        {
            ++it;
        }
        lua_pop(L, 1);
    }

    return 0;
}


// skeleton:eject(obj)
static int ejectObject(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    if (!lua_istable(L, 2))
    {
        luaL_argerror(L, 2, "Expected displayObject");
        return 0;
    }

    auto &injections = skeletonUserdata->injections;
    for (auto it = injections.begin(); it != injections.end();)
    {
        it->pushObject(L);
        if (lua_equal(L, -1, 2))
        {
            it = injections.erase(it);
            break;
        }
        else
        {
            ++it;
        }
        lua_pop(L, 1);
    }

    skeletonUserdata->groupInsert->pushTable(L);
    lua_getfield(L, 1, "stage");
    lua_pushvalue(L, 2);
    lua_call(L, 2, 0);

    return 0;
}



// skeleton:clearTracks()
static int clearTracks(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    SkeletonCallGuard guard(skeletonUserdata);
    skeletonUserdata->state->clearTracks();

    return 0;
}

// skeleton:clearTrack(trackIndex)
static int clearTrack(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    int trackIndex = checkTrackIndex(L, 2);

    SkeletonCallGuard guard(skeletonUserdata);
    skeletonUserdata->state->clearTrack(trackIndex);

    return 0;
}

// skeleton:split(slots)
static int split(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    int argCount = lua_gettop(L);
    if (argCount < 2)
    {
        luaL_error(L, "Expected 2 arguments: self, slots");
        return 0;
    }

    if (!lua_istable(L, 2))
    {
        luaL_argerror(L, 2, "Expected table");
        return 0;
    }

    // get vector of slot indices for the table of slot names
    std::vector<int> slotIndices;
    lua_pushnil(L);

    while (lua_next(L, 2) != 0)
    {
        if (lua_isstring(L, -1))
        {
            const char *slotName = lua_tostring(L, -1);
            Slot *slot = skeletonUserdata->skeleton->findSlot(slotName);
            if (slot)
            {
                slotIndices.push_back(slot->getData().getIndex());
            }
            else
            {
                luaL_error(L, "Slot not found: %s", slotName);
                return 0;
            }
        }
        lua_pop(L, 1);
    }


    SplitData &splitData = skeletonUserdata->splitData;

    if (!splitData.isSplitted())
    {
        // we create a new group and set it as the parent of the splitted skeleton
        skeletonUserdata->newGroup->pushTable(L);
        lua_call(L, 0, 1);
        splitData.setGroup(L, -1);
    }

    splitData.setSlotIndices(slotIndices);

    splitData.pushGroup(L);

    return 1;
}


// skeleton:reassemble()
static int reassemble(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    SplitData &splitData = skeletonUserdata->splitData;

    if (splitData.isSplitted())
    {
        LuaTableHolder group = splitData.releaseGroup();

        // re-draw so all meshes are in the right place (through the guard, like draw: injection listeners may raise)
        SkeletonCallGuard guard(skeletonUserdata);
        int nargs = lua_gettop(L);
        lua_pushlightuserdata(L, skeletonUserdata);
        lua_pushcclosure(L, skeletonRenderCall, 1);
        lua_insert(L, 1);
        guard.call(L, nargs, 0);

        // remove group (the guard keeps the skeleton alive: a dispose requested meanwhile runs when it ends)
        skeletonUserdata->groupRemoveSelf->pushTable(L);
        group.pushTable(L);
        guard.call(L, 1, 0);
    }

    return 0;
}




// skeleton:removeSelf(): removes the display group like any display object; Solar2D finalizes it at the end of
// the frame (spine_onFinalize) and the next frame frees the skeleton.
static int removeSelf(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata || skeletonUserdata->disposeRequested)
    {
        return 0;
    }

    skeletonUserdata->markRemoved();

    skeletonUserdata->groupRemoveSelf->pushTable(L);
    lua_pushvalue(L, 1);
    lua_call(L, 1, 0);

    return 0;
}


void getSkeletonMt(lua_State *L)
{
    luaL_getmetatable(L, "SpineSkeleton");
    if (lua_isnil(L, -1))
    {
        lua_pop(L, 1);
        luaL_newmetatable(L, "SpineSkeleton");

        lua_pushcfunction(L, skeleton_gc);
        lua_setfield(L, -2, "__gc");
    }
}

void getSpineObjectMt(lua_State *L)
{
    luaL_getmetatable(L, "SpineObject");
    if (lua_isnil(L, -1))
    {
        lua_pop(L, 1);
        luaL_newmetatable(L, "SpineObject");

        lua_pushstring(L, "__index");
        lua_pushcfunction(L, skeleton_index);
        lua_settable(L, -3);

        lua_pushstring(L, "__newindex");
        lua_pushcfunction(L, skeleton_newindex);
        lua_settable(L, -3);

        luaL_Reg methods[] = {
            {"updateState", updateState},
            {"draw", skeletonDraw},
            {"removeSelf", removeSelf},
            {"setFillColor", setFillColor},
            {"getBounds", getBounds},
            {"getSize", getSize},

            {"setDefaultMix", setDefaultMix},
            {"setMix", setMix},

            {"setToSetupPose", setToSetupPose},
            {"setBonesToSetupPose", setBonesToSetupPose},
            {"setSlotsToSetupPose", setSlotsToSetupPose},

            {"setAnimation", setAnimation},
            {"addAnimation", addAnimation},
            {"addAnimationAt", addAnimationAt},
            {"setEmptyAnimation", setEmptyAnimation},
            {"addEmptyAnimation", addEmptyAnimation},
            {"setEmptyAnimations", setEmptyAnimations},
            {"findAnimation", findAnimation},
            {"getCurrentAnimation", getCurrentAnimation},
            {"getTrackEntry", getTrackEntry},
            {"getAnimations", getAnimations},
            {"setListener", setListener},

            {"findSlot", findSlot},
            {"getSlot", getSlot},
            {"getSlotNames", getSlotNames},

            {"getIKConstraint", getIKConstraint},
            {"getIKConstraintNames", getIKConstraintNames},

            {"getSkins", getSkins},
            {"setSkin", setSkin},
            {"createSkin", createSkin},
            {"getSkin", getSkin},
            {"registerSkin", registerSkin},

            {"clearTracks", clearTracks},
            {"clearTrack", clearTrack},

            {"setAttachment", setAttachment},

            {"getDrawOrder", getDrawOrder},
            {"inject", injectObject},
            {"eject", ejectObject},
            {"changeInjectionSlot", changeInjectionSlot},

            {"split", split},
            {"reassemble", reassemble},

            {NULL, NULL}};
        luaL_register(L, NULL, methods);
    }
}
