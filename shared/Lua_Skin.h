#pragma once

#include "CoronaLua.h"
#include "spine/spine.h"
#include "DataHolder.h"
#include <map>

using namespace spine;

void getSkinMt(lua_State* L);

// All wrappers of a custom skin share ownership, including skeleton:getSkin().
struct LuaSkinOwner
{
    Skin *skin;
    bool ownsMemory;
    LuaSkinOwner(Skin *skin, bool ownsMemory) : skin(skin), ownsMemory(ownsMemory) {}
    ~LuaSkinOwner() { if (ownsMemory) delete skin; }
};

inline std::shared_ptr<LuaSkinOwner> getLuaSkinOwner(Skin *skin, bool ownsMemory = false)
{
    static std::map<Skin *, std::weak_ptr<LuaSkinOwner>> owners;
    for (auto it = owners.begin(); it != owners.end(); )
        if (it->second.expired()) it = owners.erase(it); else ++it;
    auto owner = owners[skin].lock();
    if (!owner) {
        owner = std::make_shared<LuaSkinOwner>(skin, ownsMemory);
        owners[skin] = owner;
    }
    return owner;
}

struct LuaSkin
{
    lua_State *L;
    Skin *skin;
    SkeletonData *skeletonData;
    // Declare data first so skin destruction happens before resource destruction.
    std::shared_ptr<DataHolder<SkeletonData>> dataOwner;
    std::shared_ptr<LuaSkinOwner> owner;

    LuaSkin(lua_State *L, Skin *skin, SkeletonData *skeletonData = nullptr,
            bool ownsMemory = false,
            std::shared_ptr<DataHolder<SkeletonData>> dataOwner = nullptr)
        : L(L), skin(skin), skeletonData(skeletonData), dataOwner(dataOwner),
          owner(getLuaSkinOwner(skin, ownsMemory))
    {
        getSkinMt(L);
        lua_setmetatable(L, -2);
    }
};
