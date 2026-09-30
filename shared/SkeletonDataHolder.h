#pragma once

#include "CoronaLua.h"
#include <memory>
#include "DataHolder.h"
#include <spine/SkeletonData.h>
#include "LuaTableHolder.h"

using namespace spine;

class SkeletonDataHolder : public DataHolder<SkeletonData>
{
public:
    SkeletonDataHolder(SkeletonData *object, lua_State *L, int atlasIndex);
    ~SkeletonDataHolder();

    void setAtlas(Atlas *atlas) { atlas_ = atlas; }

    // The Atlas the skeleton data was loaded with: not owned, alive as long as the holder (atlasLuaHolder refs its
    // userdata). Every DataHolder<SkeletonData> spine.loadSkeletonData makes is a SkeletonDataHolder; nullptr for none.
    static Atlas *atlasOf(const std::shared_ptr<DataHolder<SkeletonData>> &owner)
    {
        return owner ? static_cast<SkeletonDataHolder *>(owner.get())->atlas_ : nullptr;
    }

private:
    lua_State *L_;
    LuaTableHolder atlasLuaHolder;
    Atlas *atlas_ = nullptr;
};