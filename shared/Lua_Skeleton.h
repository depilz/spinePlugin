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
    LuaTableHolder *luaSelf;
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

            luaSelf->releaseTable();
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
            luaSelf = nullptr;
        }
    }
};


void getSkeletonMt(lua_State *L);
void getSpineObjectMt(lua_State *L);
