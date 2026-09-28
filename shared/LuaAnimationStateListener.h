#include "CoronaLua.h"
#include "LuaTableHolder.h"
#include "SpineCompat.h"

class LuaAnimationStateListener : public spine::AnimationStateListenerObject
{
public:
    LuaAnimationStateListener(lua_State *L, LuaTableHolder *luaSelf, int listenerRef)
        : mainState_(CoronaLuaGetCoronaThread(L)), luaSelf_(luaSelf), listenerRef_(listenerRef)
    {
    }

    ~LuaAnimationStateListener()
    {
        if (listenerRef_ != LUA_NOREF)
        {
            luaL_unref(mainState_, LUA_REGISTRYINDEX, listenerRef_);
            listenerRef_ = LUA_NOREF;
        }
        luaSelf_ = nullptr;
    }

    void callback(spine::AnimationState *state, spine::EventType type, spine::TrackEntry *entry, spine::Event *event) override
    {
        lua_State *L = mainState_;
        int top = lua_gettop(L);

        lua_rawgeti(L, LUA_REGISTRYINDEX, listenerRef_);
        lua_createtable(L, 0, 6);

        lua_pushstring(L, "name");

        if (type == spine::EventType_Event)
        {
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
            lua_pushstring(L, "spine");
            lua_rawset(L, -3);

            lua_pushstring(L, "looping");
            lua_pushboolean(L, entry->getLoop() ? 1 : 0);
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
            default:
                lua_pushstring(L, "unknown");
                break;
            }
            lua_rawset(L, -3);
        }

        lua_pushstring(L, "animation");
        lua_pushstring(L, spc::anim(*entry).getName().buffer());
        lua_rawset(L, -3);

        lua_pushstring(L, "trackIndex");
        lua_pushinteger(L, entry->getTrackIndex() + 1);
        lua_rawset(L, -3);

        lua_pushstring(L, "target");
        luaSelf_->pushTable(L);
        lua_rawset(L, -3);

        // Solar2D reports the error (traceback, unhandledError) without raising: a longjmp here would cross drain().
        // Only locals are used afterwards: the listener may have replaced this object (setListener).
        CoronaLuaDoCall(L, 1, 0);
        lua_settop(L, top);
    }

private:
    lua_State *mainState_;
    LuaTableHolder *luaSelf_;
    int listenerRef_;
};
