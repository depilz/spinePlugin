local spine = require("plugin.spine")
local which = arg[1]
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj = spine.create(data)
local slot = obj:getSlot("head")
local bone = obj.bones[1]
local ik = obj.ikConstraints[1]
local physics = obj.physics
local fill = obj.fill
print("before: slot ok", slot ~= nil, "bone", bone ~= nil, "ik", ik ~= nil, "physics", physics, "fill.r", fill.r)
obj:removeSelf()
collectgarbage(); collectgarbage()
print("after removeSelf + GC, touching", which)
if which == "slot" then print(pcall(function() return slot.color end))
elseif which == "bone" then print(bone.x)
elseif which == "ik" then print(ik.mix)
elseif which == "fill" then print(fill.r)
elseif which == "obj" then print(pcall(function() return obj.isActive end)); print(pcall(function() obj:updateState(16) end))
end
print("survived")
