#pragma once

#include "CoronaLua.h"
#include "SpineCompat.h"
#include "DataHolder.h"
#include <map>

using namespace spine;

void getSkinMt(lua_State* L);

// Lua 5.1 has no luaL_testudata: returns the userdata if its metatable is tname's, else nullptr (never raises).
inline void *luaL_testudata_compat(lua_State *L, int index, const char *tname)
{
    void *p = lua_touserdata(L, index);
    if (!p || !lua_getmetatable(L, index)) return nullptr;
    luaL_getmetatable(L, tname);
    bool same = lua_rawequal(L, -1, -2);
    lua_pop(L, 2);
    return same ? p : nullptr;
}

// A skin argument is a skin name or a Skin object of skeletonData; anything else raises.
Skin *luaL_checkSkinArg(lua_State *L, int argIndex, SkeletonData *skeletonData);
// A slot argument is a slot name or a live Slot object of skeletonData; anything else raises (numbers included).
// Returns the slot index.
int luaL_checkSlotArg(lua_State *L, int argIndex, SkeletonData *skeletonData);

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

    // A data skin belongs to the SkeletonData (not Lua-owned) and is read-only.
    bool isDataSkin() const { return !owner || !owner->ownsMemory; }
};
