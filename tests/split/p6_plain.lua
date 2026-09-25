-- baseline without split (mirrors Simulator scenarios plain/plainmm): 120 frames
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
for _, case in ipairs({ { "raptor", nil, "walk" }, { "mix-and-match", "full-skins/girl", "walk" } }) do
  local obj = C.spine.create(C.data(case[1], 0.4))
  if case[2] then obj:setSkin(case[2]) end
  obj:setAnimation(1, case[3], true)
  local errs = 0
  for f = 1, 120 do local ok = pcall(C.frame, obj); C.mock.endFrame(); if not ok then errs = errs + 1 end end
  print(case[1] .. " 120 frames, draw errors " .. errs)
  C.expect(errs == 0, case[1] .. ": draw errors without split")
end
C.done()
