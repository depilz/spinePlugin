local spine = require("plugin.spine")
local mode = arg[1] or "pool"
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj = spine.create(data)
local e = obj:setAnimation(1, "walk", true)
print("entry.animation", e.animation, "loop", e.loop)
if mode == "pool" then
  obj:clearTrack(1)              -- entry is ended+disposed and returned to AnimationState's pool
  print("after clearTrack: stale entry.animation =", e.animation)
  local e2 = obj:setAnimation(1, "run", false)  -- pool hands the same TrackEntry object back
  print("new entry.animation", e2.animation, "; stale wrapper now reports", e.animation, "loop", e.loop)
  e.timeScale = 0                 -- stale wrapper silently mutates the NEW animation
  print("new entry timeScale after writing through the stale wrapper:", e2.timeScale)
elseif mode == "removed" then
  local tracks = obj.tracks
  obj:removeSelf()
  print("after removeSelf: reading stale TrackEntry")
  print(e.animation)
elseif mode == "tracks" then
  local tracks = obj.tracks
  obj:removeSelf()
  collectgarbage()
  print("after removeSelf: #tracks", #tracks)
  print(tracks[1])
end
