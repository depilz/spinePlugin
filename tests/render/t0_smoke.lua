local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local data = C.data("raptor", 0.5)
local obj = C.spine.create(data)
obj.x, obj.y = 100, 200
obj:setAnimation(1, obj:getAnimations()[1], true)
for f = 1, 5 do C.frame(obj) end
local errs = C.check(obj, "raptor")
print("children:", #C.mock.children(obj), "errors:", #errs)
for i = 1, math.min(5, #errs) do print(errs[i]) end
for k, v in pairs(C.mock.stats) do io.write(k, "=", v, " ") end print()
C.expect(#errs == 0, "raptor: group contents differ from the oracle")
C.done()
