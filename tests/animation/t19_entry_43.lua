-- T19 (4.3 only): trackEntry.additive and trackEntry.mixInterpolation (I14 D12, D13).
-- mode = additive | interpolation | badvalue
--   additive       a bool, false by default; on track 2 it moves the pose away from the replacing control, on track 1
--                  at alpha 1 it changes nothing (upstream ignores it there)
--   interpolation  "linear" by default, each of the five names reads back, the write leaves mixDuration as it was,
--                  and "smooth" moves a mid-mix pose away from the "linear" control
--   badvalue       a non-string or unknown name raises listing the five names and keeps the stored name
local spine = require("plugin.spine")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local mode = arg[1]
local data = spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas"))
local NAMES = { "linear", "smooth", "slowFast", "fastSlow", "circle" }
local BAD = "SpineTrackEntry: mixInterpolation must be one of 'linear', 'smooth', 'slowFast', 'fastSlow', 'circle'"

-- raises(f, message): f raised an error ending in message
local function raises(f, message)
  local ok, err = pcall(f)
  print("  raised:", not ok, err)
  return not ok and tostring(err):sub(-#message) == message
end
-- pose(obj, ms): obj stepped ms in 16 ms frames and drawn; its bones' world position sums
local function pose(obj, ms)
  for _ = 1, ms / 16 do obj:updateState(16) end
  obj:draw()
  local x, y = 0, 0
  for _, b in ipairs(obj.bones) do x, y = x + b.worldX, y + b.worldY end
  print("  pose:", x, y)
  return x, y
end
local function same(ax, ay, bx, by) return math.abs(ax - bx) < 1e-3 and math.abs(ay - by) < 1e-3 end
-- layered(additive): walk on track 1, aim on track 2 with the given additive flag; the pose after 160 ms
local function layered(additive)
  local s = spine.create(data)
  s:setAnimation(1, "walk", true)
  s:setAnimation(2, "aim", true).additive = additive
  return pose(s, 160)
end
-- single(additive): walk alone on track 1 with the given additive flag; the pose after 160 ms
local function single(additive)
  local s = spine.create(data)
  s:setAnimation(1, "walk", true).additive = additive
  return pose(s, 160)
end
-- mixed(name): walk, then run mixing in over 400 ms with the named interpolation; the pose 96 ms into the mix
local function mixed(name)
  local s = spine.create(data)
  s:setAnimation(1, "walk", true)
  s:updateState(16)
  local e = s:setAnimation(1, "run", true)
  e.mixDuration = 400
  e.mixInterpolation = name
  return pose(s, 96)
end

if mode == "additive" then
  local e = spine.create(data):setAnimation(1, "walk", true)
  C.expect(e.additive == false, "a new entry is additive")
  e.additive = true
  C.expect(e.additive == true, "additive = true did not read back")
  e.additive = false
  C.expect(e.additive == false, "additive = false did not read back")
  local rx, ry = layered(false)
  C.expect(same(rx, ry, layered(false)), "control: two replacing skeletons differ, the observable is noisy")
  C.expect(not same(rx, ry, layered(true)), "an additive track 2 posed like the replacing control")
  local sx, sy = single(false)
  C.expect(same(sx, sy, single(true)), "additive on track 1 at alpha 1 changed the pose")
elseif mode == "interpolation" then
  local e = spine.create(data):setAnimation(1, "walk", true)
  C.expect(e.mixInterpolation == "linear", "a new entry's mixInterpolation is not linear: " .. tostring(e.mixInterpolation))
  e.mixDuration = 250
  for _, name in ipairs(NAMES) do
    e.mixInterpolation = name
    C.expect(e.mixInterpolation == name, "mixInterpolation did not read back " .. name)
    C.expect(e.mixDuration == 250, "writing mixInterpolation changed mixDuration: " .. e.mixDuration)
  end
  local lx, ly = mixed("linear")
  C.expect(same(lx, ly, mixed("linear")), "control: two linear mixes differ, the observable is noisy")
  C.expect(not same(lx, ly, mixed("smooth")), "a smooth mix posed like the linear control")
elseif mode == "badvalue" then
  local e = spine.create(data):setAnimation(1, "walk", true)
  e.mixInterpolation = "circle"
  for _, value in ipairs({ 1, true, {}, "Linear", "custom", "" }) do
    C.expect(raises(function() e.mixInterpolation = value end, BAD), "no raise listing the names for " .. tostring(value))
  end
  C.expect(raises(function() e.mixInterpolation = nil end, BAD), "no raise listing the names for nil")
  C.expect(e.mixInterpolation == "circle", "a bad write changed the stored name: " .. tostring(e.mixInterpolation))
end
print("end of script")
C.done()
