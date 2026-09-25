local spine = require("plugin.spine")
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj
local log = {}
local function second(e) log[#log + 1] = "second:" .. (e.phase or e.name) end
obj = spine.create(data, function(e)
  log[#log + 1] = "first:" .. (e.phase or e.name)
  if e.phase == "ended" then obj:setListener(second) end        -- replace listener while it is running
end)
obj:setAnimation(1, "walk", true); obj:updateState(16)
obj:setAnimation(1, "run", true)     -- interrupt + ended(+disposed after mix) of walk
obj:updateState(16)
obj:setListener(function(e) if e.phase == "began" then obj:setListener(nil) end end)
obj:setAnimation(1, "idle", true); obj:updateState(16)
print(table.concat(log, " "))
print("survived")
