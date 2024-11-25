#pragma once

#include "CoronaLua.h"
#include <string>
#include <cassert>
#include <vector>
#include "LuaTableHolder.h"
#include "LuaAnimationStateListener.h"
#include "MeshManager.h"
#include "InjectedObject.h"

using namespace spine;


struct SpineSkeleton
{
    Skeleton *skeleton;
    AnimationState *state;
    AnimationStateData *stateData;
    SkeletonData *skeletonData;
    LuaAnimationStateListener *stateListener;
    LuaTableHolder *groupmt__index;
    LuaTableHolder *groupmt__newindex;
    LuaTableHolder *groupInsert;
    LuaTableHolder *groupRemoveSelf;
    LuaTableHolder *newMesh;
    InjectedObject injection;
    int skeletonDataRef;
    lua_State *L;

    MeshManager meshes;
    std::vector<int> meshIndices;

    SpineSkeleton(lua_State *L)
        : skeleton(nullptr), state(nullptr), stateData(nullptr),
          skeletonData(nullptr),
          meshes(20), meshIndices(20),
          stateListener(nullptr), 
          groupmt__index(nullptr), groupmt__newindex(nullptr),
          injection(), skeletonDataRef(LUA_NOREF), 
          L(L)
    {
    }

    ~SpineSkeleton()
    {
        if (skeleton)
        {
            delete state;
            delete stateData;
            delete skeleton;

            meshIndices.clear();
            meshes.clear();
            injection.clear();

            if (stateListener)
            {
                delete stateListener;
                stateListener = nullptr;
            }

            groupmt__index = nullptr;
            groupmt__newindex = nullptr;
            groupInsert = nullptr;
            groupRemoveSelf = nullptr;
            newMesh = nullptr;

            luaL_unref(L, LUA_REGISTRYINDEX, skeletonDataRef);
            skeletonDataRef = LUA_NOREF;

            L = nullptr;

            skeleton = nullptr;
            state = nullptr;
            stateData = nullptr;
            skeletonData = nullptr;
        }
    }
};


void getSkeletonMt(lua_State *L);
void getSpineObjectMt(lua_State *L);
int skeleton_index(lua_State *L);
int skeleton_newindex(lua_State *L);
int skeleton_gc(lua_State *L);

int getSkins(lua_State *L);
int setSkin(lua_State *L);

int setToSetupPose(lua_State *L);

int setAnimation(lua_State *L);
int addAnimation(lua_State *L);
int findAnimation(lua_State *L);
int getCurrentAnimation(lua_State *L);
int getAnimations(lua_State *L);

int setDefaultMix(lua_State *L);
int setMix(lua_State *L);

int updateState(lua_State *L);
int skeletonDraw(lua_State *L);
void skeletonRender(lua_State *L, SpineSkeleton *skeletonUserdata);

int setAttachment(lua_State *L);

int getSlots(lua_State *L);

int setTimeScale(lua_State *L);
int getTimeScale(lua_State *L);

int physicsRotate(lua_State *L);
int physicsTranslate(lua_State *L);

int setFillColor(lua_State *L);

int injectObject(lua_State *L);
int ejectObject(lua_State *L);

int clearTracks(lua_State *L);
int removeSelf(lua_State *L);
