-- Inject into a MIDDLE slot and hide its region attachment via attachment.color = {a = 0}.
-- t13_midinject.lua [atlas skel], default raptor.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock, spine = C.mock, C.spine
local atlasPath, skelPath = arg[1] or "raptor/raptor.atlas", arg[2] or "raptor/raptor.skel"
local atlas = spine.loadAtlas(atlasPath)
local data = spine.loadSkeletonData(skelPath, atlas, 0.5)
local obj = spine.create(data)
obj:setAnimation(1, "walk", true)
obj:updateState(16); obj:draw()
local order = obj:getDrawOrder()
local target
for i = math.floor(#order / 2), #order do
  local s = obj:getSlot(order[i]); local a = s.attachment
  if a and a.type == "region" then target = s; break end
end
print("target slot:", target.name, target.attachment.name)
obj:inject(display.newRect(0, 0, 5, 5), target.name)
obj:updateState(16); obj:draw()
print("injected, draw ok; meshes in group:", #mock.children(obj))
target.attachment.color = { a = 0 }
local ok, err = pcall(function() obj:updateState(16); obj:draw() end)
print("after hiding the attachment: draw ok?", ok, err or "")
C.expect(ok, "draw fails after hiding the injected slot's attachment (render-2)")
C.done()
