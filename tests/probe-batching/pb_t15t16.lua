-- ports of render fx/t15_inject_order.lua (36 visible placements, raptor walk) and release tests/t16_hidden_injection_order.lua
-- (21 hidden-region placements) to the split fixture. t15 is reported twice: with its original SELF-REFERENTIAL oracle (the
-- tree's own batched command list decides where the object should be) and with the independent per-slot reference.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock, fx = C.mock, C.fx
-- t15
local obj = C.spine.create(C.data("raptor", 0.5))
obj:setAnimation(1, "walk", true); C.frame(obj)
local names = obj:getSlotNames()
local total, badSelf, badRef = 0, 0, 0
for idx, s in ipairs(names) do
  local marker = display.newRect(0, 0, 1, 1)
  obj:inject(marker, s); C.frame(obj)
  local want, n = nil, 0
  for _, c in ipairs(fx.expected(obj)) do if c.numIndices >= 3 then n = n + 1 end; if c.injectionSlot == idx - 1 then want = n end end
  if want then
    total = total + 1
    local got = 0
    for _, ch in ipairs(mock.children(obj)) do if ch == marker then break end; if mock.kind(ch) == "mesh" then got = got + 1 end end
    if got ~= want then badSelf = badSelf + 1 end
    for _, e in ipairs(C.check(obj, nil, { { obj = marker, slot = s } }, "t15")) do if e:find("injected object") then badRef = badRef + 1; break end end
  end
  obj:eject(marker); marker:removeSelf()
end
print(("t15 visible placements: %d slots with a drawn command; misplaced vs own batched list %d; vs independent reference %d"):format(total, badSelf, badRef))
obj:removeSelf(); mock.endFrame()
-- t16
obj = C.spine.create(C.data("raptor", 0.5))
obj:setAnimation(1, "walk", true); C.frame(obj)
local function above(marker)
  local seen, n = false, 0
  for _, ch in ipairs(mock.children(obj)) do if ch == marker then seen = true elseif seen and mock.kind(ch) == "mesh" then n = n + (mock.vertexCount(ch) or 0) end end
  return seen and n or -1
end
local checked, misplaced, refbad, orderbad = 0, 0, 0, 0
for _, s in ipairs(names) do
  local a = fx.attachmentAlpha(obj, s)
  if fx.attachmentKind(obj, s) == "region" and a and a > 0 then
    local marker = display.newRect(0, 0, 1, 1)
    obj:inject(marker, s); obj:draw()
    local ref = above(marker)
    fx.setAttachmentAlpha(obj, s, 0)
    local ok = pcall(obj.draw, obj)
    local hid = ok and above(marker) or -2
    local e = C.check(obj, nil, { { obj = marker, slot = s } }, "t16")
    for _, x in ipairs(e) do if x:find("injected object") then refbad = refbad + 1; break end end
    for _, x in ipairs(e) do if not x:find("injected object") then orderbad = orderbad + 1; break end end
    fx.setAttachmentAlpha(obj, s, a)
    obj:eject(marker); marker:removeSelf(); obj:draw()
    checked = checked + 1
    if hid ~= ref then misplaced = misplaced + 1 end
  end
end
print(("t16 hidden-injection placement: %d slots checked, %d misplaced (geometry above the marker changed), %d misplaced vs reference, %d frames with mesh-order errors"):format(checked, misplaced, refbad, orderbad))
C.expect(badSelf + badRef == 0, "t15: visible injections misplaced")
C.expect(misplaced + refbad == 0, "t16: hiding the injected slot's region moves the injected object (render-2)")
C.expect(orderbad == 0, "t16: mesh order wrong after hiding the injected slot's region (render-2)")
C.done()
