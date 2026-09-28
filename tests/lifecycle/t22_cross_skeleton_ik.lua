local spine = require("plugin.spine")
local S = __stub
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local a = spine.create(data)
local b = spine.create(data)
local ik = a.ikConstraints[1]; ik.mix = 1
print("IK", ik ~= nil, "targeting a bone of ANOTHER skeleton (same data):")
S.raises("target bone must belong to the same skeleton", function() ik.target = b.bones[2] end)
local own = a.bones[2]
ik.target = own
assert(ik.target.name == own.name, "a target of the same skeleton is accepted")
local bBone = b.bones[2]
a:setAnimation(1, "walk", true)
a:updateState(16); a:draw()
b:removeSelf(); S.frame(); collectgarbage(); collectgarbage()
print("b removed; targeting its retained bone")
S.raises("Bone belongs to a removed skeleton", function() ik.target = bBone end)
print("drawing a")
a:updateState(16); a:draw()
print("survived")
