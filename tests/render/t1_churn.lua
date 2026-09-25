-- Steady-state per-frame work of skeleton:updateState()+draw() through the real bindings against the Solar2D mock.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock, fx = C.mock, C.fx
local list = {
  {"spineboy"}, {"raptor"}, {"hero"}, {"alien"}, {"tank"}, {"celestial-circus"}, {"snowglobe"}, {"windmill"},
  {"goblins", skin = "goblin"}, {"mix-and-match", skin = "full-skins/girl"}, {"dragon"}, {"cloud-pot"},
}
local FR = tonumber(arg and arg[1]) or 120
local keys = {"newMesh", "meshRemoveSelf", "pathUpdate", "insert", "fillSet", "blendSet", "setFillColor", "effectSet", "xySet"}
print(("%-17s %6s %6s %6s %6s %6s %6s %6s %6s | %7s %7s %8s %8s | %s"):format("skeleton", "meshes", "new/f", "rm/f", "upd/f", "ins/f", "fill/f", "blend/f", "color/f", "KB/f", "KBupd/f", "us upd/f", "us draw/f", "oracle"))
for _, e in ipairs(list) do
  local name = e[1]
  local data = C.data(name, 0.5)
  local obj = C.spine.create(data)
  if e.skin then obj:setSkin(e.skin) end
  local anims = obj:getAnimations()
  local tot = {}; local frames = 0; local kb, kbu, tu, td = 0, 0, 0, 0; local errs = 0; local firstErr; local maxMeshes = 0
  for ai = 1, math.min(#anims, 4) do
    obj:setAnimation(1, anims[ai], true)
    C.frame(obj) -- settle (not measured)
    for f = 1, FR do
      mock.resetStats()
      collectgarbage("stop")
      local m0 = collectgarbage("count"); local t0 = os.clock()
      obj:updateState(1000 / 60)
      local m1 = collectgarbage("count"); local t1 = os.clock()
      obj:draw()
      local t2 = os.clock(); local m2 = collectgarbage("count")
      collectgarbage("restart")
      kb = kb + (m2 - m1); kbu = kbu + (m1 - m0); tu = tu + (t1 - t0); td = td + (t2 - t1)
      for _, k in ipairs(keys) do tot[k] = (tot[k] or 0) + (mock.stats[k] or 0) end
      frames = frames + 1
      local ee = C.check(obj, name)
      if #ee > 0 then errs = errs + 1; firstErr = firstErr or ee[1] end
      local n = #mock.children(obj); if n > maxMeshes then maxMeshes = n end
    end
  end
  local function pf(k) return (tot[k] or 0) / frames end
  print(("%-17s %6d %6.2f %6.2f %6.1f %6.2f %6.2f %6.2f %6.2f | %7.2f %7.3f %8.1f %8.1f | %s"):format(name, maxMeshes,
    pf("newMesh"), pf("meshRemoveSelf"), pf("pathUpdate"), pf("insert"), pf("fillSet"), pf("blendSet"), pf("setFillColor"),
    kb / frames, kbu / frames, 1e6 * tu / frames, 1e6 * td / frames, errs == 0 and "ok" or (errs .. " bad frames: " .. firstErr)))
  C.expect(errs == 0, name .. ": " .. tostring(firstErr))
  obj:removeSelf()
end
C.done()
