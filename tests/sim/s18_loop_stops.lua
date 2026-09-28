-- S18 (RT-OF-12): an object whose app loop stops shows no pose or event change across frames. Updates stay
-- app-driven: whatever the plugin runs per frame by itself (a next-frame dispose hook, triggered here by removing a
-- second object) must never update, apply or draw a skeleton, nor dispatch its animation events.
local L = require("simlib")
L.watchdogMs = 20000
L.open("s18_loop_stops")
L.expect("pose", "events")
local spine = L.loadPlugin()
local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.3)
local events = { a = 0, b = 0 }
local a = spine.create(data, function() events.a = events.a + 1 end)
local b = spine.create(data, function() events.b = events.b + 1 end)
a.x, a.y, b.x, b.y = 250, 700, 550, 700
a:setAnimation(1, "run", true); b:setAnimation(1, "run", true) -- "run" fires a footstep event twice a cycle

-- pose: every bone's local and world transform
local function pose(obj)
  local t = {}
  for _, bone in ipairs(obj.bones) do
    t[#t + 1] = ("%s %.4f %.4f %.4f %.4f %.4f"):format(bone.name, bone.x, bone.y, bone.rotation, bone.worldX, bone.worldY)
  end
  return table.concat(t, "\n")
end

local frame = 0
local appLoop
appLoop = function()
  frame = frame + 1
  for _, obj in ipairs({ a, b }) do
    if obj.removeSelf then obj:updateState(1000 / 60) end
    if obj.removeSelf then obj:draw() end
  end
  if frame < 60 then return end
  Runtime:removeEventListener("enterFrame", appLoop)
  local pose0, events0 = pose(a), { a = events.a, b = events.b }
  L.log("app loop stopped after", frame, "frames; listener calls so far a", events0.a, "b", events0.b)
  b:removeSelf()
  local watched = 0
  local function watch()
    watched = watched + 1
    if watched < 60 then return end
    Runtime:removeEventListener("enterFrame", watch)
    local same = pose(a) == pose0
    L.check("pose", same, same and "bone transforms unchanged" or "bone transforms changed after the app loop stopped")
    L.check("events", events.a == events0.a and events.b == events0.b,
      "listener calls after the stop a", events.a - events0.a, "b", events.b - events0.b)
    L.finish(0)
  end
  Runtime:addEventListener("enterFrame", watch)
end
Runtime:addEventListener("enterFrame", appLoop)
