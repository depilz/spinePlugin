#pragma once

#include "CoronaLua.h"
#include <memory>
#include "DataHolder.h"
#include "SkeletonData.h"

using namespace spine;

class SkeletonDataHolder : public DataHolder<SkeletonData>
{
public:
    SkeletonDataHolder(SkeletonData *object, lua_State *L, int atlasIndex);
    ~SkeletonDataHolder();

private:
    lua_State *L_;
    int atlasRef_;
};