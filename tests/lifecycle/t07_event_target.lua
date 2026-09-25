local spine = require("plugin.spine")
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj
local calls = 0
obj = spine.create(data, function(e)
  calls = calls + 1
  if calls == 1 then
    print("event.target == obj ?", e.target == obj, " type:", type(e.target), " == obj._skeleton ?", e.target == rawget(obj, "_skeleton"))
    print("pcall(e.target.setAnimation):", pcall(function() return e.target:setAnimation(1, "run", true) end))
  end
  error("boom from listener")   -- documented listener errors vanish silently
end)
obj:setAnimation(1, "walk", true)
obj:updateState(16)
print("listener calls:", calls, "(errors raised inside the listener were swallowed: no message printed)")
