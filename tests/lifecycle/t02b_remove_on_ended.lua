local spine = require("plugin.spine")
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj
obj = spine.create(data, function(e)
  if e.phase == "ended" and obj then local o = obj; obj = nil; print("listener: removeSelf on 'ended'"); o:removeSelf() end
end)
obj:setAnimation(1, "walk", true); obj:updateState(16)
print("clearTrack(1) ->")
obj:clearTrack(1)
print("survived")
