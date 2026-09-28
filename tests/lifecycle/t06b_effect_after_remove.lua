local spine = require("plugin.spine")
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj = spine.create(data)
obj:setAnimation(1, "walk", true); obj:updateState(16); obj:draw()
obj.fill.effect = "filter.blurGaussian"
local eff = obj.fill.effect
print("effect wrapper", eff, eff.name)
obj:removeSelf(); __stub.frame(); collectgarbage(); collectgarbage()
print("after removeSelf+GC: writing effect param through retained wrapper")
__stub.raises("Effect belongs to a removed skeleton", function() eff.horizontal = 3 end)
print("survived")
