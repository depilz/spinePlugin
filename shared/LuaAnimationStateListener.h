#include "CoronaLua.h"
#include "LuaTableHolder.h"
#include "spine/spine.h"

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

        lua_rawgeti(L, LUA_REGISTRYINDEX, listenerRef_);
        lua_createtable(L, 0, 6);

        lua_pushstring(L, "name");

        if (type == spine::EventType_Event)
        {
            lua_pushstring(L, event->getData().getName().buffer());
            lua_rawset(L, -3);

            lua_pushstring(L, "int");
            lua_pushnumber(L, event->getData().getIntValue());
            lua_rawset(L, -3);

            lua_pushstring(L, "float");
            lua_pushnumber(L, event->getData().getFloatValue());
            lua_rawset(L, -3);

            lua_pushstring(L, "string");
            lua_pushstring(L, event->getData().getStringValue().buffer());
            lua_rawset(L, -3);

            // Is this an audio event?
            if (event->getData().getAudioPath().length() > 0)
            {
                lua_pushstring(L, "audioPath");
                lua_pushstring(L, event->getData().getAudioPath().buffer());
                lua_rawset(L, -3);

                lua_pushstring(L, "volume");
                lua_pushnumber(L, event->getData().getVolume());
                lua_rawset(L, -3);

                lua_pushstring(L, "balance");
                lua_pushnumber(L, event->getData().getBalance());
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
        lua_pushstring(L, entry->getAnimation()->getName().buffer());
        lua_rawset(L, -3);

        lua_pushstring(L, "trackIndex");
        lua_pushnumber(L, entry->getTrackIndex() + 1);
        lua_rawset(L, -3);

        lua_pushstring(L, "target");
        luaSelf_->pushTable(L);
        lua_rawset(L, -3);

        if (lua_pcall(L, 1, 0, 0) != 0)
        {
            const char *err = lua_tostring(L, -1);
            lua_pop(L, 1);
        }
    }

private:
    lua_State *mainState_;
    LuaTableHolder *luaSelf_;
    int listenerRef_;
};
