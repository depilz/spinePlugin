-- S7 (lifecycle-2): obj:removeSelf() inside the 'completed' listener of a non-looping animation.
local L = require("simlib")
L.watchdogMs = 30000
L.open("s7b_single_object")
L.expect("freed", "events after removal")
local spine = L.loadPlugin()
local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.3)
local live = {}
local completedCount, removedCount, lateEvents = 0, 0, 0
local weak = setmetatable({}, { __mode = "v" }) -- the skeleton userdata of each removed object
local function spawn(x, y, anim)
  local rec = {}
  rec.obj = spine.create(data, function(event)
    if rec.removed then lateEvents = lateEvents + 1; return end
    if event.phase == "completed" and not event.looping then
      completedCount = completedCount + 1
      rec.removed = true
      local skeleton = rawget(rec.obj, "_skeleton")
      rec.obj:removeSelf()           -- the common Solar2D idiom
      rec.obj = nil
      removedCount = removedCount + 1
      weak[removedCount] = skeleton
    end
  end)
  rec.obj.x, rec.obj.y = x, y
  rec.obj:setAnimation(1, anim or "jump", false)
  live[#live + 1] = rec
  return rec
end
-- checkRemoved: the removed objects' skeleton userdata is collected and no listener ran after its removeSelf
local function checkRemoved()
  collectgarbage("collect"); collectgarbage("collect")
  local alive = 0; for i = 1, removedCount do if weak[i] then alive = alive + 1 end end
  L.check("freed", removedCount > 0 and alive == 0, ("skeleton userdata alive %d/%d removed"):format(alive, removedCount))
  L.check("events after removal", lateEvents == 0, "listener calls after removeSelf", lateEvents)
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
    timer.performWithDelay(1000, function() L.log("single object: survived 1 s after removal"); checkRemoved(); L.finish(0) end)
  else timer.performWithDelay(50, poll) end
end
poll()
