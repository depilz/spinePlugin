local spine = require("plugin.spine")
local S = __stub
local mode = arg[1] or "removeSelf"
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local scene = display.newGroup()
local obj = spine.create(data); scene:insert(obj)
obj:setAnimation(1, "walk", true); obj:updateState(16)
local splitGroup = obj:split({ "head", "eye", "mouth" })
scene:insert(splitGroup)
obj:draw()
print("split group children after draw:", #S.children(splitGroup))
if mode == "removeSelf" then
  obj:removeSelf()
  print("after obj:removeSelf(): split group removed?", S.isRemoved(splitGroup), "children:", S.children(splitGroup) and #S.children(splitGroup))
elseif mode == "removeSplit" then
  -- user removes the split group, then keeps drawing the skeleton
  splitGroup:removeSelf()
  print("split group removed by user; drawing again...")
  print(pcall(function() obj:updateState(16); obj:draw() end))
end
