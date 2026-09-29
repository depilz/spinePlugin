#pragma once

#include "CoronaLua.h"
#include <string>
#include <cassert>
#include <vector>
#include "LuaTableHolder.h"
#include "LuaAnimationStateListener.h"
#include "MeshManager.h"
#include "InjectedObject.h"
#include "SplitData.h"
#include "Lua_EffectData.h"
#include "Lua_Fill.h"
#include "DataHolder.h"
#include <memory>

using namespace spine;

struct SpineSkeleton
{
    Skeleton *skeleton;
    AnimationState *state;
    AnimationStateData *stateData;
    SkeletonData *skeletonData;
    LuaAnimationStateListener *stateListener;
    LuaTableHolder *luaSelf;
    LuaTableHolder *group__mt;
    LuaTableHolder *groupmt__index;
    LuaTableHolder *groupmt__newindex;
    LuaTableHolder *newGroup;
    LuaTableHolder *groupInsert;
    LuaTableHolder *groupRemoveSelf;
    LuaTableHolder *newMesh;
    std::vector<InjectedObject> injections;
    SplitData splitData;
    lua_State *L;
    Lua_EffectData *effectData; // created on demand when an effect is set

    MeshManager meshes;

    int busy = 0;                // > 0 while spine-cpp may call the animation listener
    bool releasePending = false; // removed while busy: luaSelf is released when that call returns

    std::shared_ptr<DataHolder<SkeletonData>> dataOwner; // keeps SkeletonData (and, through SkeletonDataHolder, the atlas) alive

    SpineSkeleton(lua_State *L)
        : skeleton(nullptr), state(nullptr), stateData(nullptr),
          skeletonData(nullptr),
          meshes(3),
          stateListener(nullptr), luaSelf(nullptr), group__mt(nullptr),
          groupmt__index(nullptr), groupmt__newindex(nullptr),
          injections(0),
          splitData(SplitData()),
          L(L),
          effectData(nullptr)
    {
    }

    ~SpineSkeleton()
    {
        if (skeleton)
        {
            delete state;
            delete stateData;
            delete skeleton;

            luaSelf->releaseTable();
            delete luaSelf; // 1.2.6: was leaked (16 B per object)
            luaSelf = nullptr;
            meshes.clear();
            injections.clear();
            splitData.clear();

            if (stateListener)
            {
                delete stateListener;
                stateListener = nullptr;
            }

            group__mt = nullptr;
            groupmt__index = nullptr;
            groupmt__newindex = nullptr;
            newGroup = nullptr;
            groupInsert = nullptr;
            groupRemoveSelf = nullptr;
            newMesh = nullptr;

            if (effectData)
            {
                delete effectData;
                effectData = nullptr;
            }

            L = nullptr;

            skeleton = nullptr;
            state = nullptr;
            stateData = nullptr;
            skeletonData = nullptr;

            dataOwner.reset(); // after the skeleton/state that use it
        }
    }
    
    void onEffectUpdated(const char *key, lua_State *L_in, int valueIndex);
};


void getSkeletonMt(lua_State *L);
void getSpineObjectMt(lua_State *L);
int spineSkeletonOnFinalize(lua_State *L);
void spineSkeletonResetFinalizeState();
