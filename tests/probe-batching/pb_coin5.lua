-- trace (animated): coin, inject coin-side (hidden, first in draw order) + coin-side-round; per-frame inserts, children, oracle
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock, fx = C.mock, C.fx
local obj = C.spine.create(C.data("coin", 0.5))
local A, B = display.newRect(0, 0, 1, 1), display.newRect(0, 0, 1, 1)
local ids = setmetatable({}, { __mode = "k" }); local nid = 0
local function nm(o) if o == A then return "A" elseif o == B then return "B" end; if not ids[o] then nid = nid + 1; ids[o] = "m" .. nid end; return ids[o] .. ":" .. tostring(mock.vertexCount(o)) end
local function kids() local t = {}; for _, ch in ipairs(mock.children(obj)) do t[#t + 1] = nm(ch) end; return table.concat(t, "|") end
mock.onInsert = function(g, a, b) if g == obj then io.write(("  ins(%s,%s)"):format(tostring(b and a or "end"), nm(b or a))) end end
obj:setAnimation(1, "animation", true)
for f = 1, 5 do C.frame(obj); mock.endFrame() end
print("start: " .. kids())
obj:inject(A, "coin-side"); obj:inject(B, "coin-side-round")
fx.setAttachmentAlpha(obj, "coin-side", 0)
local injs = { { obj = A, slot = "coin-side" }, { obj = B, slot = "coin-side-round" } }
for f = 1, 4 do
  io.write("f" .. f .. ":"); C.frame(obj); mock.endFrame(); print("  -> " .. kids())
  local t = {}; for _, c in ipairs(fx.expected(obj)) do t[#t + 1] = c.numIndices .. (c.injectionSlot >= 0 and ("[inj" .. c.injectionSlot .. "]") or "") end
  local e = C.check(obj, nil, injs, "x"); local pe = {}; for _, x in ipairs(e) do if not (x:find(": blend ") or x:find(": color ")) then pe[#pe + 1] = x end end
  print("     expected: " .. table.concat(t, " ") .. "  oracle: " .. (#pe == 0 and "ok" or pe[1]))
end
