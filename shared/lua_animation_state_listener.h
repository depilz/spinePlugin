#include "CoronaLua.h"
#include "spine/spine.h"
#include "LuaUtils.h"

class LuaAnimationStateListener : public spine::AnimationStateListenerObject
{
public:
    LuaAnimationStateListener(lua_State *L, int listener) : L(L), listener(listener) {}

    void callback(spine::AnimationState *state, spine::EventType type, spine::TrackEntry *entry, spine::Event *event) override
    {
        std::map<std::string, std::any> luaEvent = LuaUtils::newEvent("spine");

        luaEvent["animation"] = entry->getAnimation()->getName().buffer();
        luaEvent["trackIndex"] = entry->getTrackIndex();
        luaEvent["looping"] = entry->getLoop();

        switch (type)
        {
        case spine::EventType_Start:
            luaEvent["phase"] = "began";
            break;
        case spine::EventType_End:
            luaEvent["phase"] = "ended";
            break;
        case spine::EventType_Complete:
            luaEvent["phase"] = "completed";
            break;
        case spine::EventType_Event:
            luaEvent["phase"] = "event";
            luaEvent["eventName"] = event->getData().getName().buffer();
            break;
        case spine::EventType_Dispose:
            luaEvent["name"] = "disposed";
            break;
        case spine::EventType_Interrupt:
            luaEvent["name"] = "cancelled";
            break;
        default:
            break;
        }
        

        LuaUtils::dispatchEvent(listener, luaEvent);
    }

private:
    lua_State *L;
    int listener;
};
