#include "CoronaLua.h"
#include "spine/spine.h"

class LuaAnimationStateListener : public spine::AnimationStateListenerObject
{
public:
    LuaAnimationStateListener(lua_State *L, LuaTableHolder *luaSelf, int listenerRef) : L(L), luaSelf(luaSelf), listenerRef(listenerRef) {}

    void callback(spine::AnimationState *state, spine::EventType type, spine::TrackEntry *entry, spine::Event *event) override
    {
        lua_rawgeti(L, LUA_REGISTRYINDEX, listenerRef);

        lua_createtable(L, 0, 6);

        lua_pushstring(L, "name");

        if (type == spine::EventType_Event)
        {
            lua_pushstring(L, event->getData().getName().buffer());
            lua_rawset(L, -3);
        }
        else
        {
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
            default:
                lua_pushstring(L, "unknown");
                break;
            }

            lua_rawset(L, -3);
        }

        lua_pushstring(L, "animation");
        lua_pushstring(L, entry->getAnimation()->getName().buffer());
        lua_rawset(L, -3);

        lua_pushstring(L, "track");
        lua_pushnumber(L, entry->getTrackIndex());
        lua_rawset(L, -3);

        lua_pushstring(L, "looping");
        lua_pushboolean(L, entry->getLoop());
        lua_rawset(L, -3);

        lua_pushstring(L, "target");
        luaSelf->pushTable();
        lua_rawset(L, -3);

        lua_call(L, 1, 0);
    }

    ~LuaAnimationStateListener()
    {
        luaL_unref(L, LUA_REGISTRYINDEX, listenerRef);
        luaSelf = nullptr;
    }

private:
    lua_State *L;
    LuaTableHolder *luaSelf;
    int listenerRef;
};
