-- Corona/tests/SolarEffects.lua pattern: transition.loop(o.fill.effect, ...) keeps writing to the effect proxy.
-- What if the skeleton is removed (scene change) while the transition still runs?
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local obj = C.spine.create(C.data("raptor", 0.5))
obj.fill.effect = "filter.sepia"
local effect = obj.fill.effect          -- what transition.to/loop holds on to
effect.intensity = 1
obj:setAnimation(1, "walk", true); obj:updateState(16); obj:draw()
obj:removeSelf(); obj = nil
collectgarbage("collect"); collectgarbage("collect")
print("skeleton removed + GC; transition tick writes effect.intensity ...")
effect.intensity = 0.5
print("no crash (UB)")
