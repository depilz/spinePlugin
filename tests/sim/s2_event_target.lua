-- S2: what is event.target in an animation listener?
local L = require("simlib")
L.watchdogMs = 20000
L.open("s2_event_target")
L.expect("target")
local spine = L.loadPlugin()
local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.3)
local obj
local seen, wrongTarget = 0, 0
local function listener(event)
  seen = seen + 1
  if seen > 3 then return end
  local t = event.target
  if t ~= obj then wrongTarget = wrongTarget + 1 end
  L.log("event", event.name, event.phase, event.animation, "type(event.target)=" .. type(t),
    "event.target==obj " .. tostring(t == obj),
    "event.target==rawget(obj,'_skeleton') " .. tostring(t == rawget(obj, "_skeleton")))
  local ok, err = pcall(function() return t.x end)
  L.log("  event.target.x ->", ok, err)
  ok, err = pcall(function() t:setAnimation(1, "run", true) end)
  L.log("  event.target:setAnimation ->", ok, err)
end
obj = spine.create(data, listener)
obj.x, obj.y = 300, 600
obj:setAnimation(1, "jump", false)
local n = 0
Runtime:addEventListener("enterFrame", function()
  n = n + 1
  if obj.updateState then obj:updateState(1000 / 60); obj:draw() end
  if n == 90 then
    L.log("listener calls", seen)
    L.check("target", seen > 0 and wrongTarget == 0, ("event.target ~= obj in %d of %d checked listener calls"):format(wrongTarget, math.min(seen, 3)))
    L.finish(0)
  end
end)
