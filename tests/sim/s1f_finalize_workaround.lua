-- S1F: can user code work around the parent-removal leak today by calling the plugin's removeSelf from "finalize"?
local L = require("simlib")
L.watchdogMs = 30000
L.open("s1f_finalize_workaround")
L.expect("window", "freed")
local spine = L.loadPlugin()
local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.3)
local weak = setmetatable({}, { __mode = "v" })
local results, window = {}, {}
local N = 20
collectgarbage("collect"); collectgarbage("collect")
local heap0 = collectgarbage("count")
local parent = display.newGroup()
for i = 1, N do
  local obj = spine.create(data)
  parent:insert(obj)
  obj:setAnimation(1, "walk", true); obj:updateState(16); obj:draw()
  weak[i] = rawget(obj, "_skeleton")
  local pluginRemoveSelf, findAnimation = obj.removeSelf, obj.findAnimation -- the plugin's C functions
  obj:addEventListener("finalize", function(e)
    local ok, err = pcall(pluginRemoveSelf, e.target)
    results[#results + 1] = tostring(ok) .. (err and (":" .. tostring(err)) or "")
    -- the same-listener window: the fix keeps the metatable and _skeleton until RestoreTable, so a stored method still
    -- runs here; a synchronous removeSelf has already cleared _skeleton and swapped the metatable
    local _, found = pcall(findAnimation, e.target, "walk")
    local key = ("method %s, _skeleton %s"):format(tostring(found), rawget(e.target, "_skeleton") and "present" or "nil")
    window[key] = (window[key] or 0) + 1
  end)
end
display.remove(parent); parent = nil
timer.performWithDelay(300, function()
  collectgarbage("collect"); collectgarbage("collect")
  local alive = 0; for i = 1, N do if weak[i] then alive = alive + 1 end end
  local counts = {}
  for _, r in ipairs(results) do counts[r] = (counts[r] or 0) + 1 end
  for k, v in pairs(counts) do L.log("finalize -> plugin removeSelf result", k, "x" .. v) end
  for k, v in pairs(window) do L.log("finalize window after removeSelf", k, "x" .. v) end
  local intact = window["method true, _skeleton present"] or 0
  L.check("window", intact == N, ("method and _skeleton intact right after removeSelf %d/%d"):format(intact, N))
  L.log(("after display.remove(parent) with finalize workaround: skeleton userdata alive %d/%d, Lua heap delta %.1f KB"):format(alive, N, collectgarbage("count") - heap0))
  L.check("freed", alive == 0, ("skeleton userdata alive %d/%d"):format(alive, N))
  -- keep running a few frames to see whether the engine is still healthy (second collect of orphans)
  local g = display.newGroup(); local r = display.newRect(g, 100, 100, 20, 20); display.remove(g)
  timer.performWithDelay(500, function() L.log("engine still alive after 500ms"); L.finish(0) end)
end)
