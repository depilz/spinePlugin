-- S9: which Lua errors crossing the plugin are catchable by pcall in the Mac Simulator?
local L = require("simlib")
L.watchdogMs = 20000
local MODE = L.arg
L.open("s9" .. MODE .. "_error_propagation")
local spine = L.loadPlugin()
local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.3)
timer.performWithDelay(50, function()
  if MODE == "a" then
    local r = display.newRect(0, 0, 10, 10)
    local engineRemoveSelf = r.removeSelf
    L.log("a: pure engine: pcall(rect.removeSelf, {}) (plain table, no plugin involved) ...")
    local ok, err = pcall(engineRemoveSelf, {})
    L.log("a: result", ok, err)
  elseif MODE == "b" then
    local obj = spine.create(data)
    L.log("b: plugin raises directly: pcall(obj.setAnimation, obj, 0, 'walk', true) ...")
    local ok, err = pcall(obj.setAnimation, obj, 0, "walk", true)
    L.log("b: result", ok, err)
    L.log("b2: plugin error inside a Lua function inside pcall ...")
    ok, err = pcall(function() obj:setAnimation(1, "no-such-animation", true) end)
    L.log("b2: result", ok, err)
  elseif MODE == "c" then
    local obj = spine.create(data)
    obj.x, obj.y = 300, 600
    obj:setAnimation(1, "walk", true); obj:updateState(16); obj:draw()
    local marker = display.newRect(0, 0, 10, 10)
    local slotName = obj:getDrawOrder()[5]
    obj:inject(marker, slotName, function(e) error("boom in injection listener") end)
    L.log("c: Lua error() inside an injection listener (plugin lua_call, SpineRenderer.cpp:370), draw() in pcall ...")
    local ok, err = pcall(function() obj:updateState(16); obj:draw() end)
    L.log("c: result", ok, err)
  end
  timer.performWithDelay(100, function() L.log("still alive"); L.finish(0) end)
end)
