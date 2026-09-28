local spine = require("plugin.spine")
local S = __stub
local atlas = spine.loadAtlas("mix-and-match/mix-and-match.atlas")
local data = spine.loadSkeletonData("mix-and-match/mix-and-match.skel", atlas)
local a = spine.create(data)
local sk = a:createSkin("outfit"); sk:addSkin("skin-base"); sk:addSkin("nose/short")
a:setSkin(sk); a:registerSkin(sk)
sk = nil; S.gcfull()
local b = spine.create(data); b:setSkin("outfit"); b:setSlotsToSetupPose(); b:draw()
a:removeSelf(); S.frame(); S.gcfull()
b:setAnimation(1, "walk", true); b:updateState(16); b:draw()
b:removeSelf(); S.frame(); a, b, data, atlas = nil, nil, nil, nil
S.gcfull()
print("registered skin lifecycle ok; textures released", S.texturesReleased, "of", S.texturesCreated)
