-- lifecycle t16 in the real Simulator: removing a spine object twice
local L = require("simlib")
L.watchdogMs = 20000
local MODE = L.arg
L.open("s16_double_remove_" .. MODE)
local spine = L.loadPlugin()
local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.3)
local img = display.newGroup(); display.remove(img)
L.log("native group: display.remove twice (same frame) ->", pcall(display.remove, img))
local obj = spine.create(data)
display.remove(obj)
L.log("spine: after display.remove: getmetatable", tostring(getmetatable(obj)), "_skeleton", type(rawget(obj, "_skeleton")))
local function second()
  L.log("spine: display.remove again (" .. MODE .. " frame) ...")
  L.log("  ->", pcall(display.remove, obj))
  L.log("spine: obj.x ->", pcall(function() return obj.x end))
  L.log("spine: obj:removeSelf() again ...")
  L.log("  ->", pcall(function() obj:removeSelf() end))
  timer.performWithDelay(200, function() L.log("still alive"); L.finish(0) end)
end
if MODE == "same" then second() else timer.performWithDelay(100, second) end
