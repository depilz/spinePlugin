-- port of release W/tests/t16_dump.lua to the split fixture (portable API: fx.setAttachmentAlpha instead of a.color)
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local mock, fx = C.mock, C.fx
local obj = C.spine.create(C.data("raptor", 0.5))
obj:setAnimation(1, "walk", true); C.frame(obj)
local sname = arg[1] or "raptor-horn-back"
local marker = display.newRect(0, 0, 1, 1)
local function dump(tag)
  local t = {}
  for i, c in ipairs(fx.expected(obj)) do t[#t + 1] = ("%d:%d%s"):format(i, c.numIndices, c.injectionSlot and c.injectionSlot >= 0 and ("[inj" .. c.injectionSlot .. "]") or "") end
  print(tag .. " expected:", table.concat(t, " "))
  t = {}
  for i, ch in ipairs(mock.children(obj)) do
    if ch == marker then t[#t + 1] = "MARKER" elseif mock.kind(ch) == "mesh" then t[#t + 1] = tostring(mock.vertexCount(ch)) else t[#t + 1] = mock.kind(ch) end
  end
  print(tag .. " children:", table.concat(t, " | "))
  local e = C.check(obj, nil, { { obj = marker, slot = sname } }, tag)
  print(tag .. " oracle:", #e == 0 and "ok" or table.concat(e, " ; "):sub(1, 300))
end
obj:inject(marker, sname); obj:draw(); dump("visible")
local keep = fx.attachmentAlpha(obj, sname)
fx.setAttachmentAlpha(obj, sname, 0)
obj:draw(); dump("hidden d1"); obj:draw(); dump("hidden d2")
fx.setAttachmentAlpha(obj, sname, keep)
obj:draw(); dump("restored")
