#include "SkeletonDataHolder.h"

SkeletonDataHolder::SkeletonDataHolder(SkeletonData *object, lua_State *L, int atlasIndex)
    : DataHolder<SkeletonData>(object), L_(L), atlasRef_(LUA_NOREF)
{
    lua_pushvalue(L, atlasIndex);
    atlasRef_ = luaL_ref(L, LUA_REGISTRYINDEX);
}

SkeletonDataHolder::~SkeletonDataHolder()
{
    if (atlasRef_ != LUA_NOREF)
    {
        luaL_unref(L_, LUA_REGISTRYINDEX, atlasRef_);
    }
}