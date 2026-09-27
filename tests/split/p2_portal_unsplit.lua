-- spineboy 'portal' (clipping) WITHOUT split or injections: does draw() survive?
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local NAME, ANIM = arg[1] or "spineboy", arg[2] or "portal"
local obj = C.spine.create(C.data(NAME, 0.5))
obj:setAnimation(1, ANIM, false)
for f = 1, 200 do
  local ok, err = pcall(C.frame, obj)
  C.mock.endFrame()
  if not ok then C.expect(false, ("frame %d: draw failed: %s"):format(f, tostring(err))); C.done() end
  local e = C.check(obj, nil, nil, "portal f" .. f)
  if #e > 0 then C.expect(false, ("frame %d: oracle: %s"):format(f, e[1])); C.done() end
end
print(("200 frames of %s/%s unsplit: ok"):format(NAME, ANIM))
