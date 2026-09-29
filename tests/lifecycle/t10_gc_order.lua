-- GC order: SkeletonData/atlas Lua handles dropped first; skeleton, skin, slot, attachment wrappers outlive them.
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1] or "full"
local atlas = spine.loadAtlas("mix-and-match/mix-and-match.atlas")
local data = spine.loadSkeletonData("mix-and-match/mix-and-match.skel", atlas)
local obj = spine.create(data, function(e) end)
local skin = obj:createSkin("avatar")
skin:addSkin("skin-base"); skin:addSkin("nose/short"); skin:addSkin("eyes/violet"); skin:addSkin("accessories/backpack")
obj:setSkin(skin); obj:setSlotsToSetupPose()
obj:setAnimation(1, "dance", true)
local slot = obj:getSlot("backpack")
local att = slot.attachment
local dataSkin = obj:findSkin("accessories/backpack")
local atts = skin:getAttachments()
print("wrappers:", skin:getName(), att and att.name, dataSkin and dataSkin:getName(), #atts)
data, atlas = nil, nil
S.gcfull()
print("data+atlas handles collected; textures released so far:", S.texturesReleased)
for i = 1, 30 do obj:updateState(16); obj:draw() end
print("still animating/drawing OK; att.name", att.name)
if mode == "close" then print("leaving everything alive for lua_close"); return end
obj:removeSelf(); obj = nil
S.frame()
S.gcfull()
print("after removeSelf+GC: slot ->", pcall(function() return slot.attachment end))
print("att.name", att.name, "skin", skin:getName(), "dataSkin", dataSkin:getName(), "#atts", #atts, atts[1].name)
print("textures released so far:", S.texturesReleased, "(expected 0: wrappers still hold SkeletonData)")
slot, att, dataSkin, atts = nil, nil, nil, nil
S.gcfull()
print("after dropping slot/att wrappers, only custom skin left: released", S.texturesReleased)
skin = nil
S.gcfull()
print("everything dropped: textures created", S.texturesCreated, "released", S.texturesReleased)
