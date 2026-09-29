-- Corona/tests/SolarEffects.lua pattern: transition.loop(o.fill.effect, ...) keeps writing to the effect proxy.
-- If the skeleton is removed (scene change) while the transition still runs, the write must raise.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local obj = C.spine.create(C.data("raptor", 0.5))
obj.fill.effect = "filter.sepia"
local effect = obj.fill.effect          -- what transition.to/loop holds on to
effect.intensity = 1
obj:setAnimation(1, "walk", true); obj:updateState(16); obj:draw()
obj:removeSelf(); obj = nil
collectgarbage("collect"); collectgarbage("collect")
local ok, err = pcall(function() effect.intensity = 0.5 end)   -- the transition tick
print("removed skeleton + GC; effect.intensity = 0.5: ok=", ok, err or "")
C.expect(not ok and tostring(err):find("Effect belongs to a removed skeleton", 1, true),
  "effect write after removeSelf raises (render-10)")
C.done()
