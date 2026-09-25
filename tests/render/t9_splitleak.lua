-- Native heap (operator new) growth per draw(), unsplit vs split.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local fx = C.fx
local obj = C.spine.create(C.data("raptor", 0.5))
obj:setAnimation(1, "walk", true)
for f = 1, 10 do C.frame(obj) end
local function measure(label, N)
  collectgarbage("collect")
  local c0, b0, t0 = fx.newStats()
  for f = 1, N do C.frame(obj) end
  collectgarbage("collect")
  local c1, b1, t1 = fx.newStats()
  print(("%-8s %5d frames: live operator-new blocks %+d (%+d bytes), new() calls per frame %.1f"):format(label, N, c1 - c0, b1 - b0, (t1 - t0) / N))
  C.expect(c1 == c0, label .. ": native heap grows per draw (render-11)")
end
measure("unsplit", 1000)
local slots = {}
for i, s in ipairs(obj.slots) do if i % 2 == 0 then slots[#slots + 1] = s.name end end
obj._splitGroup = obj:split(slots)
for f = 1, 10 do C.frame(obj) end
measure("split", 1000)
C.done()
