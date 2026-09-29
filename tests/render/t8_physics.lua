-- Physics through the real updateState()/draw(). t8_physics.lua [skin-required|no-track]: one part, default both.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local fx = C.fx
local part = arg[1]
-- (a) updateState() steps physics (Physics_Update); draw() only poses it (Physics_Pose)
local function run(mode)
  local obj = C.spine.create(C.data("sack", 0.5))
  local info = fx.physicsInfo(obj)
  if mode == "first-inactive" then fx.makePhysicsSkinRequired(obj, 1) end
  if mode == "all-inactive" then for i = 1, #info do fx.makePhysicsSkinRequired(obj, i) end end
  obj:setAnimation(1, "walk", true)
  local traj = {}
  for f = 1, 90 do C.frame(obj, 1000 / 60); local x, y = fx.boneWorld(obj, "bone2d"); traj[f] = { x, y } end
  local pi = fx.physicsInfo(obj)
  local active = 0; for _, c in ipairs(pi) do if c.active then active = active + 1 end end
  obj:removeSelf()
  return traj, active, #pi
end
if part ~= "no-track" then
  local A, aA, n = run("normal")
  local B, aB = run("first-inactive")
  local E, aE = run("all-inactive")
  C.expect(aB == n - 1 and aE == 0, "the skin-required fixture deactivates the constraints it targets")
  local function maxdiff(p, q) local m = 0; for i = 1, #p do m = math.max(m, math.abs(p[i][1] - q[i][1]), math.abs(p[i][2] - q[i][2])) end; return m end
  print(("(a) sack: %d physics constraints. active: normal=%d, first-inactive=%d, all-inactive=%d"):format(n, aA, aB, aE))
  print(("    bone2d (not under constraint #1 'belly'): max |normal - allInactive| = %.2f, max |firstInactive - allInactive| = %.4f, max |normal - firstInactive| = %.2f")
    :format(maxdiff(A, E), maxdiff(B, E), maxdiff(A, B)))
  C.expect(maxdiff(A, B) < 0.01, "bone2d moves as with physics off when only constraint #1 is inactive (render-4)")
end

-- (b) no animation track: updateState returns early, skeleton time does not advance, physics frozen
local function idle(withEmptyTrack)
  local obj = C.spine.create(C.data("cloud-pot", 0.5))
  if withEmptyTrack then obj:setEmptyAnimation(1, 0) end
  C.frame(obj)
  local x0, y0 = fx.boneWorld(obj, "rain-blue")
  obj.physics:translate(60, 0)
  for f = 1, 30 do C.frame(obj, 1000 / 60) end
  local x1, y1 = fx.boneWorld(obj, "rain-blue")
  local _, t = fx.physicsInfo(obj)
  obj:removeSelf()
  return x1 - x0, y1 - y0, t, obj.isActive
end
if part ~= "skin-required" then
  local dx, dy, t = idle(false)
  print(("(b) cloud-pot, no track : 30 frames of updateState(16.7)+draw after physics:translate(60,0): rain-blue moved (%.1f, %.1f), skeleton time=%.3f s"):format(dx, dy, t))
  C.expect(t > 0 and (dx ~= 0 or dy ~= 0), "physics does not advance without an animation track (render-5)")
  dx, dy, t = idle(true)
  print(("    cloud-pot, empty track: same frames: rain-blue moved (%.1f, %.1f), skeleton time=%.3f s  (y>0 = down on screen)"):format(dx, dy, t))
end
C.done()
