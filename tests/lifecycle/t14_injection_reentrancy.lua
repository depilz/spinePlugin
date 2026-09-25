local spine = require("plugin.spine")
local mode = arg[1]
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj = spine.create(data)
obj:setAnimation(1, "walk", true); obj:updateState(16)
local a, b, c = display.newGroup(), display.newGroup(), display.newGroup()
local fired = false
local function listener(e)
  if fired then return end
  fired = true
  if mode == "eject" then
    print("injection listener: ejecting another injected object during draw")
    obj:eject(b); obj:eject(c)
  elseif mode == "inject" then
    print("injection listener: injecting more objects during draw")
    for i = 1, 8 do obj:inject(display.newGroup(), "head") end
  elseif mode == "remove" then
    print("injection listener: obj:removeSelf() during draw")
    obj:removeSelf()
  end
end
obj:inject(a, "head", listener)
obj:inject(b, "head", listener)
obj:inject(c, "head", listener)
obj:draw()
print("survived draw")
