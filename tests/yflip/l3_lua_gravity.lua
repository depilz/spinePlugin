-- gap-4: docs/api_reference/skeleton/physics/gravity.rst says a positive physics.gravity "simulates downward pull".
-- Check through the real Lua API (physics.gravity setter, shared/Lua_Physics.cpp:171-176) in A and B.
-- Screen is y-down in both A and B (world y == screen y). A mode passes when the xy bone is pulled down.
local fx = require("realdata_fixture")
local function check(ok, id) print((ok and "PASS" or "FAIL") .. "\t" .. id) end  -- one check row per case
local function run(mode, name, xyBone, rotBone)
  fx.setMode(mode)
  local data = fx.loadData(name .. "/" .. name .. ".atlas", name .. "/" .. name .. ".skel")
  local s = fx.create(data)
  s:setEmptyAnimation(1, 0)
  s.physics.gravity = 50
  fx.worldTransformPhysics(s)
  local x0, y0 = fx.boneWorld(s, xyBone)
  local _, _, r0 = fx.boneWorldFull(s, rotBone)
  for f = 1, 60 do s:updateState(1000 / 60); fx.worldTransformPhysics(s) end
  local x1, y1 = fx.boneWorld(s, xyBone)
  local _, _, r1 = fx.boneWorldFull(s, rotBone)
  print(("%s %-10s physics.gravity=50: xy bone %-10s screen dy %+8.2f (%s) | rotate bone %-8s screen rotation %+7.2f deg (%s)")
    :format(mode, name, xyBone, y1 - y0, y1 > y0 and "pulled DOWN" or "pulled UP", rotBone, r1 - r0, (r1 - r0) > 0 and "clockwise" or "counter-clockwise"))
  check(y1 > y0, "l3_lua_gravity " .. mode)
  fx.dispose(s); fx.setMode("A")
end
for _, m in ipairs({ "A", "B" }) do run(m, "sack", "belly", "bone") end
