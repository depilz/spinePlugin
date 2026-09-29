#pragma once

#include "CoronaLua.h"
#include "SkeletonLife.h"
#include "SpineCompat.h"
#include <memory>

using namespace spine;

// Pushes a new table snapshot of tracks: [i] = the TrackEntry wrapper of track i, or false for an empty track,
// for i = 1 ... tracks.size(). Later changes to the tracks do not reach the table; its wrappers check alive.
void pushTracks(lua_State *L, Vector<TrackEntry *> &tracks, std::shared_ptr<SkeletonLife> alive);
