-- lua_close with everything still alive (Simulator relaunch / app exit path): every __gc runs in one pass.
local spine = require("plugin.spine")
local keep = {}
local atlas = spine.loadAtlas("mix-and-match/mix-and-match.atlas")
local data = spine.loadSkeletonData("mix-and-match/mix-and-match.skel", atlas)
local atlas2 = spine.loadAtlas("spineboy/spineboy.atlas")
local data2 = spine.loadSkeletonData("spineboy/spineboy.skel", atlas2)
for i = 1, 3 do
  local d = (i % 2 == 1) and data or data2
  local obj = spine.create(d, function(e) end)
  local anims = obj:getAnimations()
  obj:setAnimation(1, anims[1], true); obj:addAnimation(1, anims[2], false, 100)
  local custom = obj:createSkin("c" .. i)
  for _, n in ipairs(obj:getSkins()) do custom:addSkin(n) end
  obj:setSkin(custom); obj:setSlotsToSetupPose()
  obj:inject(display.newGroup(), obj:getSlotNames()[3], function() end)
  obj.fill.a = 0.5
  obj.fill.effect = "filter.grayscale"
  for f = 1, 5 do obj:updateState(16); obj:draw() end
  keep[#keep + 1] = { obj = obj, entry = obj:getTrackEntry(1), tracks = obj.tracks, bone = obj.bones[1],
                      slot = obj:getSlot(obj:getSlotNames()[3]), skin = custom, att = obj:getSlot(obj:getSlotNames()[3]).attachment,
                      fill = obj.fill, split = (i == 3) and obj:split({ obj:getSlotNames()[4] }) or nil }
end
-- one removed normally, one removed via parent, one left alive
keep[1].obj:removeSelf()
local p = display.newGroup(); p:insert(keep[2].obj); p:removeSelf()
atlas, data, atlas2, data2 = nil, nil, nil, nil
collectgarbage()
print("leaving to lua_close with live wrappers, leaked skeletons, pending tracks, fill self-refs")
