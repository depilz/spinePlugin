#pragma once
#include "CoronaLua.h"
#include <memory>
#include "DataHolder.h"

class SkeletonDataHolder : public DataHolder<SkeletonData>
{
public:
    SkeletonDataHolder(SkeletonData *object, lua_State *L,  int atlasIndex);
    ~SkeletonDataHolder();

private:
    lua_State *L_;
    int atlasRef_;
};

// Constructor
SkeletonDataHolder::SkeletonDataHolder(SkeletonData *object, lua_State *L, int atlasIndex)
    : DataHolder<SkeletonData>(object), L_(L), atlasRef_(LUA_NOREF)
{
    lua_pushvalue(L, atlasIndex);
    atlasRef_ = luaL_ref(L, LUA_REGISTRYINDEX);
}

// Destructor
SkeletonDataHolder::~SkeletonDataHolder()
{
    if (atlasRef_ != LUA_NOREF)
    {
        luaL_unref(L_, LUA_REGISTRYINDEX, atlasRef_);
    }
}
