-- Remove attachments from SkeletonData-owned skins while they are displayed / used as linked-mesh parents.
local spine = require("plugin.spine")
local S = __stub
local atlas = spine.loadAtlas("goblins/goblins.atlas")
local data = spine.loadSkeletonData("goblins/goblins.json", atlas)
local a = spine.create(data)
local b = spine.create(data)
a:setSkin("goblin"); a:setSlotsToSetupPose(); a:setAnimation(1, "walk", true)
b:setSkin("goblingirl"); b:setSlotsToSetupPose(); b:setAnimation(1, "walk", true)
for f = 1, 5 do a:updateState(33); a:draw(); b:updateState(33); b:draw() end
local goblin = a:getSkin()
local headWrapper = a:getSlot("head").attachment
print("data skin:", goblin:getName(), "head attachment wrapper:", headWrapper.name)
-- goblin/left-foot is the parent + timelineAttachment of goblingirl/left-foot (linked mesh)
print("remove goblin/left-foot:", goblin:removeAttachment("left-foot", "left-foot"))
print("remove goblin/head (deform-timeline target, displayed by a):", goblin:removeAttachment("head", "head"))
for f = 1, 5 do a:updateState(33); a:draw(); b:updateState(33); b:draw() end   -- b still deforms via its parent
a:setSkin("goblingirl"); a:setSlotsToSetupPose()
for f = 1, 5 do a:updateState(33); a:draw() end
print("head wrapper still usable:", headWrapper.name)
headWrapper = nil; S.gcfull()
print("goblin skin now lacks head:", goblin:getAttachment("head", "head"))
a:setSkin("goblin"); a:setSlotsToSetupPose()
for f = 1, 5 do a:updateState(33); a:draw() end
a:removeSelf(); b:removeSelf(); goblin = nil; data = nil; atlas = nil
S.gcfull()
print("released textures:", S.texturesReleased, "of", S.texturesCreated)
