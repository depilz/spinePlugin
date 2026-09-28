#pragma once

#include "LuaTableHolder.h"
#include <memory>

// A skeleton's liveness, shared with every wrapper it hands out: dead once the skeleton is disposed, or once
// Solar2D's RestoreTable stripped the display object's metatable after finalize, so user finalize listeners still
// reach live wrappers and a user-dispatched finalize changes nothing. A skeleton with no display object (a headless
// fixture) has nothing to restore.
struct SkeletonLife
{
    bool disposed = false;
    const LuaTableHolder *self; // the skeleton's display object; outlives every check while !disposed

    explicit SkeletonLife(const LuaTableHolder *self) : self(self) {}

    explicit operator bool() const { return !disposed && (!self->isValid() || self->hasMetatable()); }
};
