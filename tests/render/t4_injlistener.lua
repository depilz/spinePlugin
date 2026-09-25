-- Injection listener: how often is it called per frame and with which isVisible values?
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local obj = C.spine.create(C.data("raptor", 0.5))
obj:setAnimation(1, "walk", true)
C.frame(obj)
local order = obj:getDrawOrder()
local slotName = order[math.floor(#order / 2)]
local calls = {}
local marker = display.newRect(0, 0, 10, 10)
obj:inject(marker, slotName, function(e) calls[#calls + 1] = e.isVisible end)
for f = 1, 3 do
  calls = {}
  C.frame(obj)
  local s = {}
  for i, v in ipairs(calls) do s[i] = tostring(v) end
  print(("frame %d: slot '%s' (draw-order %d of %d): listener calls = %d -> {%s}"):format(f, slotName, math.floor(#order / 2), #order, #calls, table.concat(s, ", ")))
  C.expect(#calls == 1 and calls[1] == true, "frame " .. f .. ": listener not called exactly once with isVisible=true (render-8)")
end
-- injected object position among group children
for i, c in ipairs(C.mock.children(obj)) do if c == marker then print("marker is child #" .. i .. " of " .. #C.mock.children(obj)) end end
-- Split variant: slot of injection NOT in split; first list is the non-split one
local g = obj:split({ order[#order] })
obj._splitGroup = g
for f = 1, 2 do
  calls = {}
  C.frame(obj)
  local s = {}
  for i, v in ipairs(calls) do s[i] = tostring(v) end
  print(("split frame %d: listener calls = %d -> {%s}"):format(f, #calls, table.concat(s, ", ")))
  C.expect(#calls == 1 and calls[1] == true, "split frame " .. f .. ": listener not called exactly once with isVisible=true (render-8)")
end
C.done()
