#include "CoronaLua.h"
#include "LuaTableHolder.h"
#include "Lua_TrackEntry.h"
#include "SkeletonLife.h"
#include "SpineCompat.h"
#include <memory>

// The skeleton's one state listener: created by create(), set on the AnimationState for the skeleton's life and
// deleted only by dispose(). setListener swaps or clears the Lua function it calls, never the object.
//
// Per-event pipeline: a removal check, then the event table, then each Lua stage in turn (entry.onComplete, the
// create() listener, the group's dispatchEvent), each stage preceded by the removal check (a removed object
// dispatches nothing more, I4; a removal inside dispatchEvent does not stop that one dispatch). A stage may swap the
// function (setListener), remove the object, or dispose it outside a guard, which deletes this listener: what a
// later stage needs is on the stack or in locals before the first Lua call. Errors are reported by CoronaLuaDoCall
// and the drain continues.
class LuaAnimationStateListener : public spine::AnimationStateListenerObject
{
public:
    LuaAnimationStateListener(lua_State *L, LuaTableHolder *luaSelf, std::shared_ptr<SkeletonLife> alive,
                              const bool *disposeRequested)
        : mainState_(CoronaLuaGetCoronaThread(L)), luaSelf_(luaSelf), removed_{std::move(alive), disposeRequested}
    {
    }

    ~LuaAnimationStateListener()
    {
        setFunction(LUA_NOREF);
        luaSelf_ = nullptr;
    }

    // Takes over a registry ref to the create()/setListener function (LUA_NOREF: none) and releases the previous one.
    // A running call keeps its function: the Lua stack holds it.
    void setFunction(int listenerRef)
    {
        if (listenerRef_ != LUA_NOREF) luaL_unref(mainState_, LUA_REGISTRYINDEX, listenerRef_);
        listenerRef_ = listenerRef;
    }

    void callback(spine::AnimationState *state, spine::EventType type, spine::TrackEntry *entry, spine::Event *event) override
    {
        const RemovalCheck removed = removed_;
        if (removed()) return;
        int onCompleteRef = type == spine::EventType_Complete ? trackEntryOnComplete(entry) : LUA_NOREF;
        lua_State *L = mainState_;
        int top = lua_gettop(L);
        luaSelf_->pushTable(L);
        int groupIndex = lua_gettop(L);
        if (onCompleteRef == LUA_NOREF && listenerRef_ == LUA_NOREF && !respondsToSpine(L, groupIndex))
        {
            lua_settop(L, top);
            return;
        }

        pushEvent(L, type, entry, event, groupIndex); // one table for every stage, target = the group
        int eventIndex = lua_gettop(L);
        // Each stage's function, taken before the first call (as Solar2D dispatches over a clone): a stage may
        // swap or clear a later one's function, or free its ref with the entry.
        lua_rawgeti(L, LUA_REGISTRYINDEX, onCompleteRef); // LUA_NOREF pushes nil
        lua_rawgeti(L, LUA_REGISTRYINDEX, listenerRef_);
        int listenerIndex = lua_gettop(L);

        // Stage 0: entry.onComplete, before the object listeners (spine-cpp calls entry listeners first).
        callStage(L, listenerIndex - 1, eventIndex);
        // Stage 1: the create()/setListener function.
        if (!removed()) callStage(L, listenerIndex, eventIndex);
        // Stage 2: the group's own dispatchEvent (Solar2D order: function listeners, then table listeners).
        if (!removed() && respondsToSpine(L, groupIndex))
        {
            lua_getfield(L, groupIndex, "dispatchEvent");
            lua_pushvalue(L, groupIndex);
            lua_pushvalue(L, eventIndex);
            CoronaLuaDoCall(L, 2, 0);
        }

        lua_settop(L, top);
    }

private:
    // Calls the function at fnIndex (nil: none) with the event table at eventIndex. Solar2D reports the error
    // (traceback, unhandledError) without raising: a longjmp here would cross drain().
    static void callStage(lua_State *L, int fnIndex, int eventIndex)
    {
        if (lua_isnil(L, fnIndex)) return;
        lua_pushvalue(L, fnIndex);
        lua_pushvalue(L, eventIndex);
        CoronaLuaDoCall(L, 1, 0);
    }

    // group:respondsToEvent("spine") read raw, without a Lua call: Solar2D's EventDispatcher keeps its listener
    // arrays in the display object's own _functionListeners/_tableListeners fields (platform/resources/init.lua).
    static bool respondsToSpine(lua_State *L, int groupIndex)
    {
        bool responds = false;
        for (const char *field : {"_functionListeners", "_tableListeners"})
        {
            lua_pushstring(L, field);
            lua_rawget(L, groupIndex);
            if (lua_istable(L, -1))
            {
                lua_pushstring(L, "spine");
                lua_rawget(L, -2);
                responds = !lua_isnil(L, -1);
                lua_pop(L, 1);
            }
            lua_pop(L, 1);
            if (responds) return true;
        }
        return false;
    }

    // Whether the object was removed (disposeRequested) or disposed. A copy outlives this listener; disposed is
    // tested first because dispose() resets disposeRequested.
    struct RemovalCheck
    {
        std::shared_ptr<SkeletonLife> alive;
        const bool *disposeRequested; // the skeleton's flag; its userdata outlives every check while !alive->disposed

        bool operator()() const { return alive->disposed || *disposeRequested; }
    };

    // Pushes the event table the Lua stages share: name="spine", a phase and target (the group at groupIndex); a
    // custom event (phase "event") adds the Spine event's name, its per-key values and its time in ms.
    void pushEvent(lua_State *L, spine::EventType type, spine::TrackEntry *entry, spine::Event *event, int groupIndex)
    {
        lua_createtable(L, 0, type == spine::EventType_Event ? 13 : 6);

        lua_pushstring(L, "name");
        lua_pushstring(L, "spine");
        lua_rawset(L, -3);

        lua_pushstring(L, "phase");

        switch (type)
        {
        case spine::EventType_Start:
            lua_pushstring(L, "began");
            break;
        case spine::EventType_End:
            lua_pushstring(L, "ended");
            break;
        case spine::EventType_Complete:
            lua_pushstring(L, "completed");
            break;
        case spine::EventType_Dispose:
            lua_pushstring(L, "disposed");
            break;
        case spine::EventType_Interrupt:
            lua_pushstring(L, "interrupted");
            break;
        case spine::EventType_Event:
            lua_pushstring(L, "event");
            break;
        default:
            lua_pushstring(L, "unknown");
            break;
        }
        lua_rawset(L, -3);

        if (type == spine::EventType_Event)
        {
            lua_pushstring(L, "event");
            lua_pushstring(L, event->getData().getName().buffer());
            lua_rawset(L, -3);

            lua_pushstring(L, "int");
            lua_pushinteger(L, spc::eventInt(*event));
            lua_rawset(L, -3);

            lua_pushstring(L, "float");
            lua_pushnumber(L, spc::eventFloat(*event));
            lua_rawset(L, -3);

            lua_pushstring(L, "string");
            lua_pushstring(L, spc::eventString(*event).buffer());
            lua_rawset(L, -3);

            lua_pushstring(L, "time");
            lua_pushnumber(L, event->getTime() * 1000);
            lua_rawset(L, -3);

            // Is this an audio event?
            if (event->getData().getAudioPath().length() > 0)
            {
                lua_pushstring(L, "audioPath");
                lua_pushstring(L, event->getData().getAudioPath().buffer());
                lua_rawset(L, -3);

                lua_pushstring(L, "volume");
                lua_pushnumber(L, spc::eventVolume(*event));
                lua_rawset(L, -3);

                lua_pushstring(L, "balance");
                lua_pushnumber(L, spc::eventBalance(*event));
                lua_rawset(L, -3);
            }
        }
        else
        {
            lua_pushstring(L, "looping");
            lua_pushboolean(L, entry->getLoop() ? 1 : 0);
            lua_rawset(L, -3);
        }

        lua_pushstring(L, "animation");
        lua_pushstring(L, spc::anim(*entry).getName().buffer());
        lua_rawset(L, -3);

        lua_pushstring(L, "trackIndex");
        lua_pushinteger(L, entry->getTrackIndex() + 1);
        lua_rawset(L, -3);

        lua_pushstring(L, "target");
        lua_pushvalue(L, groupIndex);
        lua_rawset(L, -3);
    }

    lua_State *mainState_;
    LuaTableHolder *luaSelf_;
    RemovalCheck removed_;
    int listenerRef_ = LUA_NOREF;
};
