-- S7 (lifecycle-2): obj:removeSelf() inside the 'completed' listener of a non-looping animation.
local L = require("simlib")
L.watchdogMs = 30000
L.open("s7b_single_object")
local spine = L.loadPlugin()
local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.3)
local live = {}
local completedCount, removedCount = 0, 0
local function spawn(x, y, anim)
  local rec = {}
  rec.obj = spine.create(data, function(event)
    if event.phase == "completed" and not event.looping then
      completedCount = completedCount + 1
      rec.removed = true
      rec.obj:removeSelf()           -- the common Solar2D idiom
      removedCount = removedCount + 1
    end
  end)
  rec.obj.x, rec.obj.y = x, y
  rec.obj:setAnimation(1, anim or "jump", false)
  live[#live + 1] = rec
  return rec
end
Runtime:addEventListener("enterFrame", function()
  for i = 1, #live do
    local rec = live[i]
    if not rec.removed then rec.obj:updateState(1000 / 30); if not rec.removed then rec.obj:draw() end end
  end
end)
L.log("phase 1: one spineboy, 'jump' non-looping, removeSelf in 'completed'")
spawn(300, 700)
local t0 = system.getTimer()
local function poll()
  if removedCount > 0 then
    L.log(("single object: removeSelf in 'completed' returned; %.0f ms after start"):format(system.getTimer() - t0))
    timer.performWithDelay(1000, function() L.log("single object: survived 1 s after removal"); L.finish(0) end)
  else timer.performWithDelay(50, poll) end
end
poll()
