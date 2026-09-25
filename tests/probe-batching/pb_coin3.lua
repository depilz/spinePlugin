-- trace: coin, inject coin-side (hidden, first in draw order) + coin-side-round
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock, fx = C.mock, C.fx
local obj = C.spine.create(C.data("coin", 0.5))
local A, B = display.newRect(0, 0, 1, 1), display.newRect(0, 0, 1, 1)
local function nm(o) if o == A then return "A" elseif o == B then return "B" end return tostring(mock.vertexCount(o)) .. (mock.paint(o) and mock.paint(o).blendMode ~= "normal" and ("/" .. mock.paint(o).blendMode) or "") end
local function kids() local t = {}; for _, ch in ipairs(mock.children(obj)) do t[#t + 1] = nm(ch) end; return table.concat(t, "|") end
mock.onInsert = function(g, a, b) if g == obj then io.write(("  ins(%s,%s)"):format(tostring(b and a or "end"), nm(b or a))) end end
obj:setAnimation(1, "animation", true)
io.write("f0:"); C.frame(obj); print("  -> " .. kids())
obj:inject(A, "coin-side"); obj:inject(B, "coin-side-round")
io.write("inj:"); obj:draw(); print("  -> " .. kids())
fx.setAttachmentAlpha(obj, "coin-side", 0)
for f = 1, 3 do io.write("hid" .. f .. ":"); obj:draw(); print("  -> " .. kids()) end
local t = {}; for _, c in ipairs(fx.expected(obj)) do t[#t + 1] = c.numIndices .. "/b" .. c.blend .. (c.injectionSlot >= 0 and ("[inj" .. c.injectionSlot .. "]") or "") end
print("expected: " .. table.concat(t, " "))
