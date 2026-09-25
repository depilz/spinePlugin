-- skeletonRender/renderCommands address the parent group by absolute stack index (1 = self, 2 = split group).
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local obj = C.spine.create(C.data("raptor", 0.5))
obj:setAnimation(1, "walk", true)
local g = obj:split({ "raptor-body", "raptor-horn" })
obj._splitGroup = g
local ok, err = pcall(function() obj:updateState(16); obj:draw() end)
local errs = C.check(obj, "r")
print("split, draw():       ok=", ok, err or "", "oracle errors:", #errs)
C.expect(ok and #errs == 0, "split, draw()")
ok, err = pcall(function() obj:updateState(16); obj:draw({ phase = "enterFrame" }) end)  -- e.g. obj.draw used as a listener
print("split, draw(event):  ok=", ok, err or "")
C.expect(ok, "split, draw(event) (render-13)")
obj:split({ "raptor-front-leg", "raptor-horn", "raptor-body", "raptor-back-arm" })  -- forces re-inserts
ok, err = pcall(function() obj:updateState(16); obj:draw({ phase = "enterFrame" }) end)
print("re-split, draw(event): ok=", ok, err or "")
C.expect(ok, "re-split, draw(event) (render-13)")
C.done()
