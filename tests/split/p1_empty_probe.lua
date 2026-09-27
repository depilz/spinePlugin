-- probe: which spineboy slots produce EMPTY render commands (0 indices, attachment visible) during 'portal' (clipping)
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local name, anim = arg[1] or "spineboy", arg[2] or "portal"
local obj = C.spine.create(C.data(name, 0.5))
obj:setAnimation(1, anim, false)
local empty, firstFrame = {}, {}
for f = 1, 400 do
  C.frame(obj); C.mock.endFrame()
  for _, r in ipairs(C.fx.reference(obj)) do
    if r.n == 0 then empty[r.name] = (empty[r.name] or 0) + 1; firstFrame[r.name] = firstFrame[r.name] or f end
  end
end
local t = {}
for k, v in pairs(empty) do t[#t + 1] = ("%s(%d frames, first f%d)"):format(k, v, firstFrame[k]) end
table.sort(t)
print(name .. "/" .. anim .. ": slots with empty commands: " .. (#t > 0 and table.concat(t, ", ") or "none"))
