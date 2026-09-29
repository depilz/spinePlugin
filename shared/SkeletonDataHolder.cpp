#include "SkeletonDataHolder.h"

SkeletonDataHolder::SkeletonDataHolder(SkeletonData *object, lua_State *L, int atlasIndex)
    : DataHolder<SkeletonData>(object), L_(L), atlasLuaHolder(L, atlasIndex)
{
}

SkeletonDataHolder::~SkeletonDataHolder()
{
    atlasLuaHolder.releaseTable();
}