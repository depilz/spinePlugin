-- skeleton.physicsTimeScale through the real updateState()/draw(). t16_physics_timescale.lua [default|reject|freeze].
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local fx = C.fx
local part = arg[1]
local obj = C.spine.create(C.data("cloud-pot", 0.5))
C.frame(obj)

if part == "default" then
  print("physicsTimeScale =", obj.physicsTimeScale)
  C.expect(obj.physicsTimeScale == 1, "physicsTimeScale defaults to 1")
  obj.physicsTimeScale = 0.5
  C.expect(obj.physicsTimeScale == 0.5, "physicsTimeScale reads back the written value")
  local _, t0 = fx.physicsInfo(obj)
  C.frame(obj, 100)
  local _, t1 = fx.physicsInfo(obj)
  print(("updateState(100) at 0.5: skeleton time +%.4f s"):format(t1 - t0))
  C.expect(math.abs((t1 - t0) - 0.05) < 1e-5, "physicsTimeScale scales the skeleton time step")
end

if part == "reject" then
  local message = "physicsTimeScale must be a finite number >= 0"
  -- tonumber: a 1e300 literal would be a Lua constant-table key, which UBSan flags inside Lua 5.1 itself
  for _, value in ipairs({ -1, 1 / 0, -1 / 0, 0 / 0, tonumber("1e300") }) do
    local ok, err = pcall(function() obj.physicsTimeScale = value end)
    print("physicsTimeScale =", value, "->", ok, err)
    -- luaL_error prefixes the caller's "file:line: " position
    C.expect(not ok and err:sub(-#message - 2) == ": " .. message, "rejects " .. tostring(value))
    C.expect(obj.physicsTimeScale == 1, "a rejected write leaves physicsTimeScale unchanged")
  end
  local ok = pcall(function() obj.physicsTimeScale = "x" end)
  C.expect(not ok, "rejects a non-number")
  obj.physicsTimeScale = 0
  C.expect(obj.physicsTimeScale == 0, "0 is accepted")
end

-- 0 freezes physics; returning to 1 steps one frame, not the whole paused span (no catch-up burst)
if part == "freeze" then
  local x0, y0 = fx.boneWorld(obj, "rain-blue")
  local _, t0 = fx.physicsInfo(obj)
  obj.physicsTimeScale = 0
  obj.physics:translate(60, 0)
  for f = 1, 30 do C.frame(obj, 1000 / 60) end
  local x1, y1 = fx.boneWorld(obj, "rain-blue")
  local _, t1 = fx.physicsInfo(obj)
  print(("30 frames at 0: rain-blue moved (%.3f, %.3f), skeleton time +%.4f s"):format(x1 - x0, y1 - y0, t1 - t0))
  C.expect(t1 == t0 and x1 == x0 and y1 == y0, "physicsTimeScale = 0 freezes physics")
  obj.physicsTimeScale = 1
  C.frame(obj, 1000 / 60)
  local _, t2 = fx.physicsInfo(obj)
  print(("1 frame back at 1: skeleton time +%.4f s"):format(t2 - t1))
  C.expect(math.abs((t2 - t1) - 1 / 60) < 1e-4, "resuming steps one frame, without catching up the paused span")
  for f = 1, 30 do C.frame(obj, 1000 / 60) end
  local x3, y3 = fx.boneWorld(obj, "rain-blue")
  C.expect(x3 ~= x1 or y3 ~= y1, "physics moves again after resuming")
end
obj:removeSelf()
C.done()
