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
    LuaTableHolder *group__mt;
    LuaTableHolder *groupmt__index;
    LuaTableHolder *groupmt__newindex;
    LuaTableHolder *groupInsert;
    LuaTableHolder *groupRemoveSelf;
    LuaTableHolder *newMesh;
    InjectedObject injection;
    int skeletonDataRef;
    lua_State *L;

    MeshManager meshes;

    SpineSkeleton(lua_State *L)
        : skeleton(nullptr), state(nullptr), stateData(nullptr),
          skeletonData(nullptr),
          meshes(3),
          stateListener(nullptr), luaSelf(nullptr), group__mt(nullptr),
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
            meshes.clear();
            injection.clear();

            if (stateListener)
            {
                delete stateListener;
                stateListener = nullptr;
            }

            group__mt = nullptr;
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
