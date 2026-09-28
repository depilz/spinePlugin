-- gap-6 g6: removeSelf only orphans the object; it is finalized at the end of the frame (the stub's timing).
local spine = require("plugin.spine")
local S = __stub
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local mode = arg[1]
local obj = spine.create(data)
obj:setAnimation(1, "walk", true); obj:updateState(16); obj:draw()
if mode == "read" then
  obj:removeSelf()
  print("same frame after removeSelf: obj.x =", obj.x, "obj.removeSelf =", obj.removeSelf)
  assert(obj.removeSelf == nil and obj.x == nil, "a removed object still answers display keys")
  assert(obj.numChildren == nil, "a removed object still answers numChildren")
  assert(type(obj.addEventListener) == "function", "a removed object lost its EventDispatcher keys")
  assert(pcall(display.remove, obj), "a second display.remove in the removal frame raises")
elseif mode == "write" then
  obj:removeSelf()
  print("same frame after removeSelf: obj.alpha = 0 ->", pcall(function() obj.alpha = 0 end))
  assert(rawget(obj, "__props").alpha == 0 and rawget(obj, "alpha") == nil, "the write did not reach the group")
elseif mode == "timescale" then
  obj:removeSelf()
  print("same frame after removeSelf: obj.timeScale = 2 ->", pcall(function() obj.timeScale = 2 end))
elseif mode == "listener_then_draw" then
  obj:setListener(function(e) if e.phase == "began" then obj:removeSelf() end end)
  obj:setAnimation(1, "run", true)       -- 'began' removes the object synchronously
  print("after the listener removed it: obj.removeSelf =", obj.removeSelf)
  assert(obj.removeSelf == nil, "a removed object still answers removeSelf")
  if obj.removeSelf then obj:draw() end
end
S.frame()
print("after the frame: getmetatable(obj) =", getmetatable(obj))
assert(getmetatable(obj) == nil, "the end-of-frame finalize left a metatable")
S.gcfull()
