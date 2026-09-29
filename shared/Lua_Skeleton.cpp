#include "Lua_Skeleton.h"
#include "Lua_Slot.h"
#include "Lua_Bone.h"
#include "Lua_IKConstraint.h"
#include "Lua_Physics.h"
#include "Lua_Track.h"
#include "SpineRenderer.h"

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

    return skeletonUserdata;
}

// spine-cpp calls the animation listener from inside AnimationState (EventQueue::drain). If the listener
// removes the object, the native skeleton must survive until that call has returned.
struct SkeletonBusyGuard
{
    SpineSkeleton *sk;
    explicit SkeletonBusyGuard(SpineSkeleton *s) : sk(s) { sk->busy++; }
    ~SkeletonBusyGuard()
    {
        if (--sk->busy == 0 && sk->releasePending)
        {
            sk->releasePending = false;
            sk->luaSelf->releaseTable(); // from now on the userdata can be collected (its __gc frees the skeleton)
        }
    }
};

// 1.2.6: a wrapper (slot, bone, ...) made from obj (argument 1) gets the skeleton's anchor table { userdata } as
// its environment, so the native skeleton lives while any wrapper is referenced. Wrapper on top of the stack.
static void pinToSkeleton(lua_State *L)
{
    lua_pushstring(L, "_skeleton");
    lua_rawget(L, 1);
    lua_getfenv(L, -1);
    lua_setfenv(L, -3);
    lua_pop(L, 1);
}

// 1.2.6: drop every registry reference that keeps the SpineSkeleton userdata reachable (luaSelf, the listener
// function, injected objects and their listeners, the split group). The native skeleton stays usable by held
// wrappers and is freed by the userdata's __gc once nothing references it. Meshes are kept unless asked.
static void releaseLuaRefs(SpineSkeleton *sk, bool releaseMeshes)
{
    sk->state->setListener((AnimationStateListenerObject *)NULL);
    if (sk->stateListener)
    {
        sk->stateListener->releaseRef();
    }
    sk->injections.clear();
    sk->splitData.clear();
    if (releaseMeshes)
    {
        sk->meshes.clear();
    }
    if (sk->busy > 0)
    {
        sk->releasePending = true; // luaSelf keeps the userdata alive until spine-cpp has returned
    }
    else
    {
        sk->luaSelf->releaseTable();
    }
}

static bool isSkeletonUserdata(lua_State *L, int index)
{
    if (!lua_touserdata(L, index) || !lua_getmetatable(L, index))
    {
        return false;
    }
    luaL_getmetatable(L, "SpineSkeleton");
    bool isSkeleton = lua_rawequal(L, -1, -2) != 0;
    lua_pop(L, 2);
    return isSkeleton;
}

// 1.2.6: a skeleton whose display group was finalized without obj:removeSelf() (parent group / composer scene
// removal) was pinned forever by the registry. Solar2D dispatches "finalize" to every listener first (user
// listeners may still use the object, as in 1.2.5), so it is only queued here and released on the next
// "enterFrame".
static int pendingFinalizedRef = LUA_NOREF; // registry: { [SpineSkeleton userdata] = display group table }
static int releaseFinalizedRef = LUA_NOREF; // registry: releaseFinalized (the same function value for add/remove)
static bool releaseListenerAdded = false;

static void runtimeEnterFrameListener(lua_State *L, const char *method)
{
    lua_getglobal(L, "Runtime");
    if (lua_isnil(L, -1))
    {
        lua_pop(L, 1);
        return;
    }
    lua_getfield(L, -1, method);
    lua_pushvalue(L, -2);
    lua_pushstring(L, "enterFrame");
    lua_rawgeti(L, LUA_REGISTRYINDEX, releaseFinalizedRef);
    lua_call(L, 3, 0);
    lua_pop(L, 1);
}

static int releaseFinalized(lua_State *L)
{
    runtimeEnterFrameListener(L, "removeEventListener");
    releaseListenerAdded = false;

    lua_rawgeti(L, LUA_REGISTRYINDEX, pendingFinalizedRef);
    luaL_unref(L, LUA_REGISTRYINDEX, pendingFinalizedRef);
    pendingFinalizedRef = LUA_NOREF;
    if (!lua_istable(L, -1))
    {
        return 0;
    }
    int pending = lua_gettop(L);

    lua_pushnil(L);
    while (lua_next(L, pending) != 0)
    {
        int objIndex = lua_gettop(L);   // value: display group table (key = userdata below it)
        lua_pushvalue(L, objIndex - 1); // the userdata
        lua_pushstring(L, "_skeleton");
        lua_rawget(L, objIndex);
        bool stillAttached = lua_rawequal(L, -1, -2) != 0;
        lua_pop(L, 1);

        // Solar2D removes the metatable (LuaProxy::RestoreTable) right after dispatching a real "finalize". A table
        // that still has one is a live object that got a user-dispatched "finalize": leave it alone.
        bool restoredBySolar2D = !lua_getmetatable(L, objIndex);
        if (!restoredBySolar2D)
        {
            lua_pop(L, 1);
        }

        if (stillAttached && restoredBySolar2D && isSkeletonUserdata(L, -1))
        {
            releaseLuaRefs((SpineSkeleton *)lua_touserdata(L, -1), false);
        }
        lua_settop(L, objIndex - 1); // keep the key for lua_next
    }

    return 0;
}

// "finalize" listener added by spine.create(). Solar2D dispatches it on every removal path (obj:removeSelf(),
// display.remove(parent), composer.removeScene(), ...).
int spineSkeletonOnFinalize(lua_State *L)
{
    if (!lua_istable(L, 1))
    {
        return 0;
    }

    lua_getfield(L, 1, "target");
    if (!lua_istable(L, -1))
    {
        return 0;
    }
    int objIndex = lua_gettop(L);

    lua_pushstring(L, "_skeleton");
    lua_rawget(L, objIndex);
    if (!isSkeletonUserdata(L, -1))
    {
        return 0; // removed through removeSelf()
    }
    int udIndex = lua_gettop(L);

    if (pendingFinalizedRef == LUA_NOREF)
    {
        lua_newtable(L);
        pendingFinalizedRef = luaL_ref(L, LUA_REGISTRYINDEX);
    }
    lua_rawgeti(L, LUA_REGISTRYINDEX, pendingFinalizedRef);
    lua_pushvalue(L, udIndex);
    lua_pushvalue(L, objIndex);
    lua_rawset(L, -3);
    lua_pop(L, 1);

    if (!releaseListenerAdded)
    {
        if (releaseFinalizedRef == LUA_NOREF)
        {
            lua_pushcfunction(L, releaseFinalized);
            releaseFinalizedRef = luaL_ref(L, LUA_REGISTRYINDEX);
        }
        runtimeEnterFrameListener(L, "addEventListener");
        releaseListenerAdded = true;
    }

    return 0;
}

// called from luaopen_plugin_spine: registry references do not survive a Simulator relaunch (new lua_State)
void spineSkeletonResetFinalizeState()
{
    pendingFinalizedRef = LUA_NOREF;
    releaseFinalizedRef = LUA_NOREF;
    releaseListenerAdded = false;
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

static int skeleton_index(lua_State *L)
{
    const char *key = luaL_checkstring(L, 2);

    lua_pushstring(L, "_skeleton");
    lua_rawget(L, 1);

    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

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
    else if (strcmp(key, "slots") == 0)
    {
        Skeleton *skeleton = skeletonUserdata->skeleton;
        Vector<Slot *> &slots = skeleton->getSlots();
        int n = slots.size();
        lua_createtable(L, n, 0);

        for (int i = 0; i < n; i++)
        {
            LuaSlot *slotUserdata = (LuaSlot *)lua_newuserdata(L, sizeof(LuaSlot));
            new (slotUserdata) LuaSlot(L, slots[i]);
            lua_getfenv(L, 3); // 1.2.6: pin the skeleton (see pinToSkeleton)
            lua_setfenv(L, -2);

            lua_rawseti(L, -2, i + 1);
        }

        return 1;
    }
    else if (strcmp(key, "bones") == 0)
    {
        Skeleton *skeleton = skeletonUserdata->skeleton;
        Vector<Bone *> &bones = skeleton->getBones();
        int n = bones.size();
        lua_createtable(L, n, 0);

        for (int i = 0; i < n; i++)
        {
            LuaBone *boneUserdata = (LuaBone *)lua_newuserdata(L, sizeof(LuaBone));
            new (boneUserdata) LuaBone(L, bones[i]);
            lua_getfenv(L, 3); // 1.2.6: pin the skeleton (see pinToSkeleton)
            lua_setfenv(L, -2);

            lua_rawseti(L, -2, i + 1);
        }

        return 1;
    } else if (strcmp(key, "ikConstraints") == 0)
    {
        Skeleton *skeleton = skeletonUserdata->skeleton;
        Vector<IkConstraint *> &ikConstraints = skeleton->getIkConstraints();
        int n = ikConstraints.size();
        lua_createtable(L, n, 0);

        for (int i = 0; i < n; i++)
        {
            IkConstraint *ikConstraint = ikConstraints[i];
            LuaIKConstraint *ikConstraintUserdata = (LuaIKConstraint *)lua_newuserdata(L, sizeof(LuaIKConstraint));
            new (ikConstraintUserdata) LuaIKConstraint(L, ikConstraint);
            lua_getfenv(L, 3); // 1.2.6: pin the skeleton (see pinToSkeleton)
            lua_setfenv(L, -2);

            lua_rawseti(L, -2, i + 1);
        }

        return 1;
    } else if (strcmp(key, "physics") == 0)
    {
        Vector<PhysicsConstraint*> PhysicsConstraints = skeletonUserdata->skeleton->getPhysicsConstraints();

        if (PhysicsConstraints.size() == 0)
        {
            return 0;
        }

        LuaPhysics *physicsUserdata = (LuaPhysics *)lua_newuserdata(L, sizeof(LuaPhysics));
        new (physicsUserdata) LuaPhysics(L, PhysicsConstraints);
        lua_getfenv(L, 3); // 1.2.6: pin the skeleton (see pinToSkeleton)
        lua_setfenv(L, -2);

        return 1;
    }
    else if (strcmp(key, "tracks") == 0)
    {
        Vector<TrackEntry *> &tracks = skeletonUserdata->state->getTracks();
        
        LuaTrack *entryUserdata = (LuaTrack *)lua_newuserdata(L, sizeof(LuaTrack));
        new (entryUserdata) LuaTrack(L, tracks);
        lua_getfenv(L, 3); // 1.2.6: pin the skeleton (see pinToSkeleton)
        lua_setfenv(L, -2);
        
        return 1;
    }
    else if (strcmp(key, "fill") == 0)
    {
        LuaFill *fillUserdata = (LuaFill *)lua_newuserdata(L, sizeof(LuaFill));
        new (fillUserdata) LuaFill(L, skeletonUserdata);
        lua_getfenv(L, 3); // 1.2.6: pin the skeleton (see pinToSkeleton)
        lua_setfenv(L, -2);
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

static int skeleton_newindex(lua_State *L)
{
    lua_pushstring(L, "_skeleton");
    lua_rawget(L, 1);

    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    const char *key = luaL_checkstring(L, 2);

    if (strcmp(key, "timeScale") == 0)
    {
        float timeScale = luaL_checknumber(L, 3);
        skeletonUserdata->state->setTimeScale(timeScale);
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

    if (skeletonUserdata->skeleton)
    {
        skeletonUserdata->~SpineSkeleton();
    }

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
    int n = skins.size();
    lua_createtable(L, n, 0);

    for (int i = 0; i < n; i++)
    {
        lua_pushstring(L, skins[i]->getName().buffer());
        lua_rawseti(L, -2, i + 1);
    }

    return 1;
}

// skeleton:setSkin(skinName)
static int setSkin(lua_State *L)
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

    Skeleton *skeleton = skeletonUserdata->skeleton;
    SkeletonData *skeletonData = skeletonUserdata->skeletonData;

    if (!skinName)
    {
        luaL_argerror(L, 2, "Skin name is required");
        return 0;
    }

    Skin *skin = skeletonData->findSkin(skinName);
    if (!skin)
    {
        luaL_error(L, "Skin not found: %s", skinName);
        return 0;
    }

    skeleton->setSkin(skin);
    skeleton->setSlotsToSetupPose();

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
    skeletonUserdata->skeleton->setToSetupPose();

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
    skeletonUserdata->skeleton->setBonesToSetupPose();

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
    skeletonUserdata->skeleton->setSlotsToSetupPose();

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
    int trackIndex = luaL_checkint(L, 2) - 1;
    const char *animationName = luaL_checkstring(L, 3);
    bool loop = lua_toboolean(L, 4);

    Animation *animation = skeletonUserdata->skeletonData->findAnimation(animationName);
    if (!animation)
    {
        lua_pushboolean(L, false);
        return 1;
    } 
    else if (trackIndex < 0 )
    {
        lua_pushboolean(L, false);
        luaL_error(L, "Invalid track index: %d", trackIndex + 1);
        return 1;
    }
    
    {
        SkeletonBusyGuard guard(skeletonUserdata);
        skeletonUserdata->state->setAnimation(trackIndex, animation, loop);
    }

    lua_pushboolean(L, true);

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
    int trackIndex = luaL_checkint(L, 2) - 1;
    const char *animationName = luaL_checkstring(L, 3);
    bool loop = lua_toboolean(L, 4);
    float delay = luaL_checknumber(L, 5) / 1000;

    Animation *animation = skeletonUserdata->skeletonData->findAnimation(animationName);
    if (!animation)
    {
        lua_pushboolean(L, false);
        return 1;
    }
    if (trackIndex < 0)
    {
        luaL_error(L, "Invalid track index: %d", trackIndex + 1);
        return 0;
    }

    {
        SkeletonBusyGuard guard(skeletonUserdata);
        skeletonUserdata->state->addAnimation(trackIndex, animation, loop, delay);
    }
    
    lua_pushboolean(L, true);

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
    int trackIndex = luaL_checkint(L, 2) - 1;
    float mixDuration = luaL_checknumber(L, 3) / 1000;

    if (trackIndex < 0)
    {
        luaL_error(L, "Invalid track index: %d", trackIndex + 1);
        return 0;
    }

    {
        SkeletonBusyGuard guard(skeletonUserdata);
        skeletonUserdata->state->setEmptyAnimation(trackIndex, mixDuration);
    }
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
    int trackIndex = luaL_checkint(L, 2) - 1;
    float mixDuration = luaL_checknumber(L, 3) / 1000;
    float delay = luaL_checknumber(L, 4) / 1000;

    if (trackIndex < 0)
    {
        luaL_error(L, "Invalid track index: %d", trackIndex + 1);
        return 0;
    }

    {
        SkeletonBusyGuard guard(skeletonUserdata);
        skeletonUserdata->state->addEmptyAnimation(trackIndex, mixDuration, delay);
    }
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

    // optional trackIndex
    int trackIndex = luaL_optint(L, 2, 1) - 1;

    TrackEntry *entry = skeletonUserdata->state->getCurrent(trackIndex);
    if (!entry)
    {
        lua_pushnil(L);
        return 1;
    }

    const char *animationName = entry->getAnimation()->getName().buffer();
    lua_pushstring(L, animationName);

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
    int n = animations.size();
    lua_createtable(L, n, 0);

    for (int i = 0; i < n; i++)
    {
        lua_pushstring(L, animations[i]->getName().buffer());
        lua_rawseti(L, -2, i + 1);
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

    skeletonUserdata->stateData->setMix(fromAnimation, toAnimation, mix / 1000);
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

    // check if any tracks are playing
    if (skeletonUserdata->state->getTracks().size() == 0)
    {
        return 0;
    }

    SkeletonBusyGuard guard(skeletonUserdata);
    skeletonUserdata->state->update(deltaTime);
    if (skeletonUserdata->releasePending) return 0; // removed from the listener
    skeletonUserdata->state->apply(*skeletonUserdata->skeleton);
    if (skeletonUserdata->releasePending) return 0; // removed from the listener
    skeletonUserdata->skeleton->update(deltaTime);

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

// 1.2.6: false once the caller removed the split group (directly, or with its layer / scene). Solar2D returns nil
// for `parent` of a removed object, and a finalized object is a plain table.
static bool isSplitGroupAlive(lua_State *L, SplitData &splitData)
{
    bool alive = false;
    splitData.pushGroup(L);
    if (lua_istable(L, -1))
    {
        lua_getfield(L, -1, "parent");
        alive = !lua_isnil(L, -1);
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
    return alive;
}

// 1.2.6: the split group is gone and its meshes went with it: forget them without touching them and draw the
// skeleton unsplit from now on (as if reassemble() had been called). 1.2.5 kept drawing into the dead group:
// every draw() raised, or aborted the app when a split slot needed a new mesh.
static void dropDeadSplit(SpineSkeleton *skeletonUserdata)
{
    auto &meshes = skeletonUserdata->meshes;
    for (int index = static_cast<int>(meshes.size()) - 1; index >= 0; index--)
    {
        if (meshes[index].group == 2)
        {
            meshes.removeMesh(index);
        }
    }
    skeletonUserdata->splitData.clear();
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

    if (skeletonUserdata->splitData.isSplitted() && !isSplitGroupAlive(L, skeletonUserdata->splitData))
    {
        dropDeadSplit(skeletonUserdata);
    }

    if (skeletonUserdata->splitData.isSplitted())
    {
        auto slotIndices = skeletonUserdata->splitData.getSlotIndices();
        auto commandsInSplit = skeletonUserdata->splitData.commandsInSplit;
        auto commandsNotInSplit = skeletonUserdata->splitData.commandsNotInSplit;
        auto commands = skeletonRenderer.render(*skeleton, checkInjections(L, skeletonUserdata), slotIndices, commandsInSplit, commandsNotInSplit);
        renderCommands(L, skeletonUserdata, commands->first, meshes, 1);

        if (!skeletonUserdata->releasePending) // 1.2.6: removed from an injection listener
        {
            skeletonUserdata->splitData.pushGroup(L);
            renderCommands(L, skeletonUserdata, commands->second, meshes, 2);
            lua_remove(L, 2);
        }
        delete commands; // 1.2.6: SkeletonRenderer::render returns a new std::pair every frame
    }
    else {
        command = skeletonRenderer.render(*skeleton, checkInjections(L, skeletonUserdata));

        renderCommands(L, skeletonUserdata, command, meshes, 1);
    }

    for (int index = meshes.size() - 1; index >= 0 && !skeletonUserdata->releasePending; index--)
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

static int renderProtected(lua_State *L)
{
    skeletonRender(L, (SpineSkeleton *)lua_touserdata(L, lua_upvalueindex(1)));
    return 0;
}

// 1.2.6: runs skeletonRender under the busy guard (an injection listener may call removeSelf()) in protected mode, with
// the same stack layout as before (the arguments of draw()/reassemble() at 1..n). A Lua error raised by an injection
// listener is left on the stack top (non-zero status) for the caller to re-raise once the guard has been released.
static int renderGuarded(lua_State *L, SpineSkeleton *skeletonUserdata)
{
    SkeletonBusyGuard guard(skeletonUserdata);
    int n = lua_gettop(L);
    lua_pushlightuserdata(L, skeletonUserdata);
    lua_pushcclosure(L, renderProtected, 1);
    lua_insert(L, 1);
    return lua_pcall(L, n, 0, 0);
}

// skeleton:draw()
static int skeletonDraw(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    if (skeletonUserdata->skeleton->getPhysicsConstraints().size() > 0 && skeletonUserdata->skeleton->getPhysicsConstraints()[0]->isActive())
    {
        skeletonUserdata->skeleton->updateWorldTransform(Physics_Update);
    } 
    else
    {
        skeletonUserdata->skeleton->updateWorldTransform(Physics_None);
    }

    if (renderGuarded(L, skeletonUserdata) != 0)
    {
        lua_error(L); // re-raise the injection listener's error, as 1.2.5 did
    }

    return 0;
}


// skeleton:setAttachment(slotName, attachmentName)
static int setAttachment(lua_State *L) {
    if (lua_gettop(L) != 3) {
        luaL_error(L, "Expected 3 arguments: self, slotName, attachmentName");
        return 0;
    }

    const char *slotName = luaL_checkstring(L, 2);
    const char *attachmentName = luaL_optstring(L, 3, "null");

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
    if (strcmp(attachmentName, "null") != 0) {
        Skin* skin = skeletonUserdata->skeleton->getSkin();
        if (!skin)
        {
            // 1.2.6: no skin was set with setSkin(); spine uses the default skin in that case
            skin = skeletonUserdata->skeletonData->getDefaultSkin();
        }
        if (skin)
        {
            attachment = skin->getAttachment(slot->getData().getIndex(), attachmentName);
        }
        if (!attachment) {
            luaL_error(L, "Attachment not found: %s", attachmentName);
            return 0;
        }
    }

    slot->setAttachment(attachment);

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
    new (slotUserdata) LuaSlot(L, slot);
    pinToSkeleton(L); // 1.2.6

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
    int n = slots.size();
    lua_createtable(L, n, 0);

    for (int i = 0; i < n; i++)
    {
        lua_pushstring(L, slots[i]->getData().getName().buffer());
        lua_rawseti(L, -2, i + 1);
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

    IkConstraint *ikConstraint = skeleton->findIkConstraint(ikConstraintName);

    if (!ikConstraint)
    {
        luaL_error(L, "IKConstraint not found: %s", ikConstraintName);
        return 0;
    }

    LuaIKConstraint *ikConstraintUserdata = (LuaIKConstraint *)lua_newuserdata(L, sizeof(LuaIKConstraint));
    new (ikConstraintUserdata) LuaIKConstraint(L, ikConstraint);
    pinToSkeleton(L); // 1.2.6

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
    Vector<IkConstraintData *> &ikConstraints = skeletonData->getIkConstraints();

    int n = ikConstraints.size();
    lua_createtable(L, n, 0);

    for (int i = 0; i < n; i++)
    {
        lua_pushstring(L, ikConstraints[i]->getName().buffer());
        lua_rawseti(L, -2, i + 1);
    }

    return 1;
}


// skeleton:setTimeScale(timeScale)
static int setTimeScale(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    float timeScale = luaL_checknumber(L, 2);
    skeletonUserdata->state->setTimeScale(timeScale);

    return 0;
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
    Vector<float> outVertexBuffer;

    skeleton->getBounds(outX, outY, outWidth, outHeight, outVertexBuffer);

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
    Vector<float> outVertexBuffer;

    skeleton->getBounds(outX, outY, outWidth, outHeight, outVertexBuffer);

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
    Vector<Slot *> &drawOrder = skeleton->getDrawOrder();
    int n = drawOrder.size();
    lua_createtable(L, n, 0);

    for (int i = 0; i < n; i++)
    {
        lua_pushstring(L, drawOrder[i]->getData().getName().buffer());
        lua_rawseti(L, -2, i + 1);
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

    const char *slotName = luaL_checkstring(L, 3);
    Slot *slot = skeletonUserdata->skeleton->findSlot(slotName);
    if (!slot)
    {
        luaL_error(L, "Slot not found: %s", slotName);
        return 0;
    }

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

    {
        SkeletonBusyGuard guard(skeletonUserdata);
        skeletonUserdata->state->clearTracks();
    }

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
    int trackIndex = luaL_checkint(L, 2) - 1;

    {
        SkeletonBusyGuard guard(skeletonUserdata);
        skeletonUserdata->state->clearTrack(trackIndex);
    }

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

    if (splitData.isSplitted() && !isSplitGroupAlive(L, splitData))
    {
        dropDeadSplit(skeletonUserdata); // 1.2.6: the old group was removed by the caller: start a new one
    }

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
        if (!isSplitGroupAlive(L, splitData))
        {
            // 1.2.6: already removed by the caller: Solar2D's removeSelf on a finalized table aborts the app
            dropDeadSplit(skeletonUserdata);
            if (renderGuarded(L, skeletonUserdata) != 0)
            {
                lua_error(L);
            }
            return 0;
        }

        int status;
        {
            LuaTableHolder group = splitData.releaseGroup();
            LuaTableHolder *groupRemoveSelf = skeletonUserdata->groupRemoveSelf;

            // re-draw so all meshes are in the right place
            status = renderGuarded(L, skeletonUserdata);

            if (status == 0)
            {
                // remove group
                groupRemoveSelf->pushTable(L);
                group.pushTable(L);
                lua_call(L, 1, 0);
            }
        }
        if (status != 0)
        {
            lua_error(L); // re-raise the injection listener's error, as 1.2.5 did
        }
    }

    return 0;
}




// skeleton:removeSelf()
static int removeSelf(lua_State *L)
{
    if (!lua_istable(L, 1))
    {
        luaL_error(L, "SpineSkeleton expected. If this is a function call, you might have used '.' instead of ':'");
        return 0;
    }

    lua_pushstring(L, "_skeleton");
    lua_rawget(L, 1);
    
    if (lua_isnil(L, -1))
    {
        luaL_error(L, "Skeleton already removed");
        return 0;
     }

    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    // 1.2.6: the userdata keeps its metatable (1.2.5 removed it and deleted the native skeleton at once, so wrappers
    // held past removeSelf() used freed memory). Its __gc frees the skeleton once nothing references it.

    lua_pushstring(L, "_skeleton");
    lua_pushnil(L);
    lua_rawset(L, 1);

    skeletonUserdata->groupRemoveSelf->pushTable(L);
    lua_pushvalue(L, 1);
    lua_call(L, 1, 0);

    skeletonUserdata->group__mt->pushTable(L);
    lua_setmetatable(L, 1);

    // the Lua side is released now, as the 1.2.5 destructor did (inside a listener: luaSelf when spine-cpp returns)
    releaseLuaRefs(skeletonUserdata, true);

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
            {"setEmptyAnimation", setEmptyAnimation},
            {"addEmptyAnimation", addEmptyAnimation},
            {"findAnimation", findAnimation},
            {"getCurrentAnimation", getCurrentAnimation},
            {"getAnimations", getAnimations},

            {"findSlot", findSlot},
            {"getSlot", getSlot},
            {"getSlotNames", getSlotNames},

            {"getIKConstraint", getIKConstraint},
            {"getIKConstraintNames", getIKConstraintNames},

            {"getSkins", getSkins},
            {"setSkin", setSkin},

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
