-- reproduce the coin M-case placement error with a dump of commands/children/reference
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local mock, fx = C.mock, C.fx
local obj = C.spine.create(C.data("coin", 0.5))
obj:setAnimation(1, "animation", true)
for f = 1, 33 do C.frame(obj); mock.endFrame() end
local names = {}
local ref = fx.reference(obj)
local t = {}; for _, r in ipairs(ref) do t[#t + 1] = r.name .. ":" .. r.n end; print("reference:", table.concat(t, " "))
print("slots:", table.concat(obj:getSlotNames(), " "))
for _, s in ipairs(obj:getSlotNames()) do print("  ", s, fx.attachmentKind(obj, s), fx.attachmentAlpha(obj, s)) end
