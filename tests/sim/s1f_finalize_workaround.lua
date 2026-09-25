-- S1F: can user code work around the parent-removal leak today by calling the plugin's removeSelf from "finalize"?
local L = require("simlib")
L.watchdogMs = 30000
L.open("s1f_finalize_workaround")
local spine = L.loadPlugin()
local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.3)
local weak = setmetatable({}, { __mode = "v" })
local results = {}
local N = 20
collectgarbage("collect"); collectgarbage("collect")
local heap0 = collectgarbage("count")
local parent = display.newGroup()
for i = 1, N do
  local obj = spine.create(data)
  parent:insert(obj)
  obj:setAnimation(1, "walk", true); obj:updateState(16); obj:draw()
  weak[i] = rawget(obj, "_skeleton")
  local pluginRemoveSelf = obj.removeSelf -- the plugin's C function
  obj:addEventListener("finalize", function(e)
    local ok, err = pcall(pluginRemoveSelf, e.target)
    results[#results + 1] = tostring(ok) .. (err and (":" .. tostring(err)) or "")
  end)
end
display.remove(parent); parent = nil
timer.performWithDelay(300, function()
  collectgarbage("collect"); collectgarbage("collect")
  local alive = 0; for i = 1, N do if weak[i] then alive = alive + 1 end end
  local counts = {}
  for _, r in ipairs(results) do counts[r] = (counts[r] or 0) + 1 end
  for k, v in pairs(counts) do L.log("finalize -> plugin removeSelf result", k, "x" .. v) end
  L.log(("after display.remove(parent) with finalize workaround: skeleton userdata alive %d/%d, Lua heap delta %.1f KB"):format(alive, N, collectgarbage("count") - heap0))
  -- keep running a few frames to see whether the engine is still healthy (second collect of orphans)
  local g = display.newGroup(); local r = display.newRect(g, 100, 100, 20, 20); display.remove(g)
  timer.performWithDelay(500, function() L.log("engine still alive after 500ms"); L.finish(0) end)
end)
