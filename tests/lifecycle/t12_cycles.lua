-- Heap growth across create/remove cycles (plain -O2 build; malloc_zone_statistics size_in_use).
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1] or "removeSelf"
local N = tonumber(arg[2] or "2000")
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local function cycle()
  local parent = display.newGroup()
  local obj = spine.create(data, function(e) end)
  parent:insert(obj)
  obj:setAnimation(1, "walk", true)
  for f = 1, 3 do obj:updateState(16); obj:draw() end
  if mode == "removeSelf" then obj:removeSelf(); parent:removeSelf()
  elseif mode == "parent" then parent:removeSelf()           -- composer-style indirect removal
  end
end
for i = 1, 50 do cycle() end
S.gcfull()
local h0, l0 = __native.heap(), collectgarbage("count")
for i = 1, N do cycle() end
S.gcfull()
local h1, l1 = __native.heap(), collectgarbage("count")
print(string.format("%-10s N=%d  native heap +%.1f KB (%.0f B/cycle)   Lua heap +%.1f KB (%.0f B/cycle)",
  mode, N, (h1 - h0) / 1024, (h1 - h0) / N, l1 - l0, (l1 - l0) * 1024 / N))
