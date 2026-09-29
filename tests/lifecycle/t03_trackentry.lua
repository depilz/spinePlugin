local spine = require("plugin.spine")
local S = __stub
local mode = arg[1] or "pool"
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj = spine.create(data)
local e = obj:setAnimation(1, "walk", true)
print("entry.animation", e.animation, "loop", e.loop, "isValid", e.isValid)
assert(e.isValid == true, "a current entry is valid")
if mode == "pool" then
  obj:clearTrack(1)              -- entry is ended+disposed and returned to AnimationState's pool
  print("after clearTrack: stale entry.isValid =", e.isValid)
  assert(e.isValid == false, "a cleared entry is no longer valid")
  S.raises("Track entry is no longer valid", function() return e.animation end)
  local e2 = obj:setAnimation(1, "run", false)  -- pool hands the same TrackEntry object back
  assert(e2.isValid == true and e.isValid == false, "the pooled entry's new wrapper is valid, the stale one is not")
  S.raises("Track entry is no longer valid", function() e.timeScale = 0 end)
  print("new entry.animation", e2.animation, "timeScale", e2.timeScale)
  assert(e2.timeScale == 1, "a write through the stale wrapper reached the new entry")
elseif mode == "removed" then
  local tracks = obj.tracks
  obj:removeSelf(); S.frame()
  print("after removeSelf: reading stale TrackEntry, isValid =", e.isValid)
  assert(e.isValid == false, "an entry of a removed skeleton is not valid")
  S.raises("Track entry belongs to a removed skeleton", function() return e.animation end)
elseif mode == "tracks" then
  local tracks = obj.tracks
  obj:removeSelf(); S.frame()
  collectgarbage()
  print("after removeSelf: #tracks, tracks[1]", #tracks, type(tracks[1]))
  assert(#tracks == 1 and tracks[1].isValid == false, "a held tracks snapshot keeps its entry wrappers")
  S.raises("Track entry belongs to a removed skeleton", function() return tracks[1].animation end)
end
