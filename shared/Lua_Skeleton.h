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
#include "Lua_Skin.h"

using namespace spine;

struct SpineSkeleton
{
    std::shared_ptr<DataHolder<SkeletonData>> dataOwner;
    std::shared_ptr<LuaSkinOwner> appliedSkinOwner;
    std::shared_ptr<SkeletonLife> alive = std::make_shared<SkeletonLife>(&luaSelf);
    Skeleton *skeleton;
    AnimationState *state;
    AnimationStateData *stateData;
    SkeletonData *skeletonData;
    LuaAnimationStateListener *stateListener;
    LuaTableHolder luaSelf; // the display object (event.target); released in dispose()
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
    float physicsTimeScale = 1; // scales only the dt given to skeleton->update, i.e. Spine physics constraint time

    MeshManager meshes;

    SpineSkeleton(lua_State *L)
        : skeleton(nullptr), state(nullptr), stateData(nullptr),
          skeletonData(nullptr),
          meshes(3),
          stateListener(nullptr), group__mt(nullptr),
          groupmt__index(nullptr), groupmt__newindex(nullptr),
          injections(0),
          splitData(SplitData()),
          L(L),
          effectData(nullptr)
    {
    }

    // busy > 0 while a plugin call that can run Lua callbacks is on the C stack (see SkeletonCallGuard).
    int busy = 0;
    bool disposeRequested = false; // removed: no further update, apply, draw or event; freed by the next-frame hook
    bool disposeDeferred = false;  // the hook ran while busy: the outermost guard disposes

    // Removal (removeSelf): through indexing, the object stops updating, drawing and dispatching events now; memory stays valid.
    void markRemoved()
    {
        disposeRequested = true;
        // a removed display object dispatches no further events: stop the rest of the current drain
        if (state) state->setListener((AnimationStateListenerObject *)NULL);
    }

    // Next-frame hook (or finalize without Runtime): wrappers stop working now; native cleanup waits while busy.
    void requestDispose()
    {
        if (!skeleton) return;
        alive->disposed = true;
        if (busy > 0)
        {
            markRemoved();
            disposeDeferred = true;
            return;
        }
        dispose();
    }

    ~SpineSkeleton()
    {
        dispose();
    }

    // Idempotent native cleanup; the struct stays valid (members reset) so __gc can run it again safely.
    void dispose()
    {
        alive->disposed = true;
        disposeRequested = false;
        disposeDeferred = false;
        if (skeleton)
        {
            delete state;
            delete stateData;
            delete skeleton;

            luaSelf.releaseTable();
            meshes.clear();
            injections.clear();
            splitData.clear();

            if (stateListener)
            {
                delete stateListener;
                stateListener = nullptr;
            }

            // groupmt__index/__newindex (static holders) stay: a disposed object still resolves EventDispatcher keys
            group__mt = nullptr;
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
            appliedSkinOwner.reset();
            dataOwner.reset();
        }
    }
    
    void onEffectUpdated(const char *key, lua_State *L_in, int valueIndex);
};


// RAII guard for plugin entry points that can run Lua callbacks: a dispose requested meanwhile runs when the
// outermost guard ends. Lua raises by longjmp, which skips destructors: release() before raising, and run a
// callback that may raise through call().
struct SkeletonCallGuard
{
    SpineSkeleton *s;
    explicit SkeletonCallGuard(SpineSkeleton *s) : s(s) { s->busy++; }
    ~SkeletonCallGuard() { release(); }
    SkeletonCallGuard(const SkeletonCallGuard &) = delete;
    SkeletonCallGuard &operator=(const SkeletonCallGuard &) = delete;

    void release()
    {
        if (!s) return;
        SpineSkeleton *owner = s;
        s = nullptr;
        if (--owner->busy == 0 && owner->disposeDeferred) owner->dispose();
    }

    // lua_call that releases the guard before re-raising the callback's error.
    void call(lua_State *L, int nargs, int nresults)
    {
        if (lua_pcall(L, nargs, nresults, 0) != 0)
        {
            release();
            lua_error(L);
        }
    }
};

int spine_onFinalize(lua_State *L);
void resetDisposeQueue(); // luaopen: registry refs do not survive a Simulator relaunch (new lua_State)

void getSkeletonMt(lua_State *L);
void getSpineObjectMt(lua_State *L);
