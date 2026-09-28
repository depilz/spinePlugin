local spine = require("plugin.spine")
local S = __stub
local which = arg[1]
-- spineboy has no physics constraint, so the physics branch uses cloud-pot
local skeleton = which == "physics" and { file = "cloud-pot/cloud-pot", ext = ".skel", slot = "rain/rain-green" }
  or { file = "spineboy/spineboy", ext = ".json", slot = "head" }
local atlas = spine.loadAtlas(skeleton.file .. ".atlas")
local data = spine.loadSkeletonData(skeleton.file .. skeleton.ext, atlas)
local obj = spine.create(data)
local slot = obj:getSlot(skeleton.slot)
local bone = obj.bones[1]
local ik = obj.ikConstraints[1]
local physics = obj.physics
local fill = obj.fill
print("before: slot ok", slot ~= nil, "bone", bone ~= nil, "ik", ik ~= nil, "physics", physics, "fill.r", fill.r)
obj:removeSelf(); __stub.frame()
collectgarbage(); collectgarbage()
print("after removeSelf + GC, touching", which)
if which == "slot" then print(pcall(function() return slot.color end))
elseif which == "bone" then S.raises("Bone belongs to a removed skeleton", function() return bone.x end)
elseif which == "ik" then S.raises("IK constraint belongs to a removed skeleton", function() return ik.mix end)
elseif which == "physics" then S.raises("Physics constraint belongs to a removed skeleton", function() return physics.mix end)
elseif which == "fill" then S.raises("Fill belongs to a removed skeleton", function() return fill.r end)
elseif which == "obj" then print(pcall(function() return obj.isActive end)); print(pcall(function() obj:updateState(16) end))
end
print("survived")
