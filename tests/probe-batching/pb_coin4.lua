-- coin: all pairs of injected slots (optionally one hidden); counts only placement/order errors (P, R), not paint (Q)
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local mock, fx = C.mock, C.fx
local S = { "coin-side", "coin-side-round", "coin-front-texture", "coin-front-shine", "shine" }
local bad, total = 0, 0
for i = 1, #S do for j = 1, #S do if i ~= j then for hide = 0, 2 do
  local obj = C.spine.create(C.data("coin", 0.5))
  obj:setAnimation(1, "animation", true)
  for f = 1, 5 do C.frame(obj); mock.endFrame() end
  local ms = {}
  local injs = {}
  for _, s in ipairs({ S[i], S[j] }) do local m = display.newRect(0, 0, 1, 1); ms[s] = m; obj:inject(m, s); injs[#injs + 1] = { obj = m, slot = s } end
  local hs = hide == 1 and S[i] or (hide == 2 and S[j] or nil)
  local keep = hs and fx.attachmentAlpha(obj, hs)
  if hs and keep then fx.setAttachmentAlpha(obj, hs, 0) end
  local firstErr
  for f = 1, 10 do C.frame(obj); mock.endFrame(); local e = C.check(obj, nil, injs, "x"); total = total + 1; local pe = {}; for _, x in ipairs(e) do if x:find("injected object") or x:find("vertices") or x:find("meshes in group") then pe[#pe + 1] = x end end; if #pe > 0 then bad = bad + 1; firstErr = firstErr or pe end end
  if firstErr then
    local t = {}; for _, c in ipairs(fx.expected(obj)) do t[#t + 1] = c.numIndices .. (c.injectionSlot >= 0 and ("[inj" .. c.injectionSlot .. "]") or "") end
    local k = {}; for _, ch in ipairs(mock.children(obj)) do local nm = mock.kind(ch) == "mesh" and tostring(mock.vertexCount(ch)) or "?"; for s, m in pairs(ms) do if m == ch then nm = "M(" .. s .. ")" end end; k[#k + 1] = nm end
    local r = {}; for _, x in ipairs(fx.reference(obj)) do r[#r + 1] = x.name .. ":" .. x.n end
    print(("inject %s + %s, hide %s: %s"):format(S[i], S[j], tostring(hs), firstErr[1]))
    print("   expected: " .. table.concat(t, " ") .. " | children: " .. table.concat(k, " | ") .. " | ref: " .. table.concat(r, " "))
  end
  if hs and keep then fx.setAttachmentAlpha(obj, hs, keep) end
  obj:removeSelf(); mock.endFrame()
end end end end
print(("coin pairs: %d/%d frames bad"):format(bad, total))
C.expect(bad == 0, bad .. " frames with an injected object misplaced (render-1)")
C.done()
