#pragma once

#include "CoronaLua.h"
#include "SkeletonLife.h"
#include "SpineCompat.h"
#include <memory>

using namespace spine;

void getBoneMt(lua_State* L);

struct LuaBone
{
    lua_State *L;
    Bone *bone;
    Skeleton *skeleton; // the owner, for a root bone's world position (4.3's Bone has no getSkeleton())
    std::shared_ptr<SkeletonLife> alive;

    LuaBone(lua_State *L, Bone *bone, Skeleton *skeleton, std::shared_ptr<SkeletonLife> alive)
        : L(L), bone(bone), skeleton(skeleton), alive(alive)
    {
        getBoneMt(L);
        lua_setmetatable(L, -2);
    }

    void checkAlive(lua_State *state) const
    {
        if (!bone || (alive && !*alive))
            luaL_error(state, "Bone belongs to a removed skeleton");
    }

    ~LuaBone()
    {
        bone = nullptr;
        skeleton = nullptr;
        L = nullptr;
    }
};

