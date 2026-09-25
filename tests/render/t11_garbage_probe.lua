local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local obj = C.spine.create(C.data("raptor", 0.3))
obj:setAnimation(1, obj:getAnimations()[1], true)
for i = 1, 30 do C.frame(obj) end
local function probe(label, fn, n)
  collectgarbage("collect"); collectgarbage("stop")
  local k0 = collectgarbage("count"); for i = 1, n do fn() end
  print(("%-40s %.3f KB/call"):format(label, (collectgarbage("count") - k0) / n)); collectgarbage("restart")
end
probe("obj:updateState(16.7)", function() obj:updateState(16.7) end, 200)
probe("obj:draw()", function() obj:draw() end, 200)
probe("obj.draw lookup only", function() local f = obj.draw end, 200)
probe("obj.x lookup (group __index fallback)", function() local f = obj.x end, 200)
