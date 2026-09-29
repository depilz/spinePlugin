-- spine.create() poses the skeleton and draw() poses without stepping physics: bone world reads and getBounds right
-- after create() equal those after a first and a second draw() with no updateState() between them.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local function world(obj)
  local out = {}
  for _, b in ipairs(obj.bones) do out[#out + 1] = { b.name, b.worldX, b.worldY, b.a, b.b, b.c, b.d } end
  local bounds = obj:getBounds()
  out[#out + 1] = { "bounds", bounds.xMin, bounds.yMin, bounds.xMax, bounds.yMax }
  return out
end
local function differ(p, q)
  local n = 0
  for i, row in ipairs(p) do
    for j = 2, #row do if row[j] ~= q[i][j] then n = n + 1 end end
  end
  return n
end
-- raptor has no physics; cloud-pot's rotate-offset physics drifts under a zero-delta Physics_Update
for _, rig in ipairs({ "raptor", "sack", "cloud-pot" }) do
  local obj = C.spine.create(C.data(rig, 0.5))
  local created = world(obj)
  obj:draw()
  local first = world(obj)
  obj:draw()
  local second = world(obj)
  local d1, d2 = differ(created, first), differ(first, second)
  print(("%s: %d bones; world values differing create->draw: %d, draw->draw: %d"):format(rig, #created - 1, d1, d2))
  C.expect(d1 == 0, rig .. ": world transform after create() equals the first draw()'s")
  C.expect(d2 == 0, rig .. ": a second draw() without updateState() moves nothing")
  obj:removeSelf()
end
-- create() must not consume the physics reset: 30 strict-cadence frames equal those of the same rig whose physics
-- state is reset after create(), i.e. as if create() ran no transform. An Update/Reset at create kicks the first frame.
for _, ra in ipairs({ { "sack", "walk" }, { "cloud-pot", "pot-moving-followed-by-rain" } }) do
  local rig, anim = ra[1], ra[2]
  local obj, ref = C.spine.create(C.data(rig, 0.5)), C.spine.create(C.data(rig, 0.5))
  C.fx.resetPhysics(ref)
  obj:setAnimation(1, anim, true)
  ref:setAnimation(1, anim, true)
  local frames = 0
  for _ = 1, 30 do
    C.frame(obj, 1000 / 60)
    C.frame(ref, 1000 / 60)
    if differ(world(obj), world(ref)) > 0 then frames = frames + 1 end
  end
  print(("%s %s: strict-cadence frames differing from the reset-physics reference: %d/30"):format(rig, anim, frames))
  C.expect(frames == 0, rig .. ": create() leaves the physics reset for the first updateState()")
  obj:removeSelf()
  ref:removeSelf()
end
C.done()
