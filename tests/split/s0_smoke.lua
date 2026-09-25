local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
for _, name in ipairs({ "raptor", "spineboy", "tank", "mix-and-match", "celestial-circus" }) do
  local obj = C.spine.create(C.data(name, 0.5))
  local anims = obj:getAnimations()
  obj:setAnimation(1, anims[1], true)
  local bad = 0
  for f = 1, 30 do C.frame(obj); C.mock.endFrame(); local e = C.check(obj, nil, nil, name); if #e > 0 then bad = bad + 1; if bad == 1 then print(e[1]) end end end
  local ref = C.fx.reference(obj)
  local main = C.fx.expected(obj)
  print(("%-18s unsplit: frames bad=%d, commands=%d, ref slots=%d"):format(name, bad, #main, #ref))
  C.expect(bad == 0, name .. ": unsplit frames disagree with the oracle")
  obj:removeSelf(); C.mock.endFrame()
end
C.done()
