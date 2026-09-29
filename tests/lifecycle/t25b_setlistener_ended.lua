local spine = require("plugin.spine")
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj
local log = {}
local function second(e) log[#log + 1] = "second:" .. (e.phase or e.name) end
obj = spine.create(data, function(e)
  log[#log + 1] = "first:" .. (e.phase or e.name)
  if e.phase == "ended" then obj:setListener(second) end   -- swaps the running listener's function
end)
obj:setAnimation(1, "walk", true); obj:updateState(16)
obj:clearTrack(1)                                          -- drains: ended -> (listener replaced) -> disposed
print(table.concat(log, " "))
print("survived")
