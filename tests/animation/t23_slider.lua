-- T23 (4.3 only): obj.sliders and its SpineSlider wrappers (I14 D16, A4), in the ASan+UBSan host. diamond's slider
-- "rotation" plays its animation "rotation" (keys the middle-rotation and top-rotation bones and the shine slots'
-- sequences) at a time the bone "diamond-rotation-control" drives.
-- mode = read | write | detach | removed | bone | sequence
--   read      obj.sliders is a fresh name-keyed table of the skeleton's sliders; every key reads; ikConstraints skips
--             sliders; __eq compares the native slider
--   write     a time write moves the bones the slider's animation keys, mix = 0 stops it; read-only, unknown and
--             non-number writes raise and change nothing
--   detach    the bone drives the time until a time write, which takes the slider from its bone for good
--   removed   a wrapper of a removed skeleton raises the lifecycle error on read, write and ==
--   bone      a time write detaches the bone, then the skeleton (and so the bone) is removed and collected while
--             the slider and bone wrappers are held
--   sequence  a copy of a sequence attachment the slider's animation keys, shown on two skeletons while their sliders
--             scrub it, outlives both
local spine = require("plugin.spine")
local S = __stub
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local mode = arg[1]
local REMOVED = "Slider belongs to a removed skeleton"

local data = spine.loadSkeletonData("diamond/diamond.json", spine.loadAtlas("diamond/diamond.atlas"))

-- raises(f, message): f raised an error ending in message
local function raises(f, message)
  local ok, err = pcall(f)
  print("  raised:", not ok, err)
  return not ok and tostring(err):sub(-#message) == message
end
-- bone(s, name): the skeleton's bone of that name
local function bone(s, name)
  for _, b in ipairs(s.bones) do
    if b.name == name then return b end
  end
end
-- pose(s): the slider-keyed bones' world rotations after an update, printed
local function pose(s)
  s:updateState(0)
  local middle, top = bone(s, "middle-rotation").worldRotation, bone(s, "top-rotation").worldRotation
  print("  middle-rotation:", middle, "top-rotation:", top, "time:", s.sliders.rotation.time)
  return middle, top
end
local function near(a, b) return math.abs(a - b) < 1e-3 end

if mode == "read" then
  local s = spine.create(data)
  local sliders = s.sliders
  local names = {}
  for name in pairs(sliders) do names[#names + 1] = name end
  print("  sliders:", table.concat(names, " "))
  C.expect(#names == 1 and sliders.rotation ~= nil, "sliders is not keyed by the one slider's name")
  local slider = sliders.rotation
  print("  time:", slider.time, "mix:", slider.mix, "duration:", slider.duration, "loop:", slider.loop,
    "boneDriven:", slider.boneDriven)
  C.expect(slider.name == "rotation" and slider.animation == "rotation", "the name keys")
  C.expect(slider.loop == true and slider.boneDriven == true and slider.mix == 1, "the setup keys")
  C.expect(type(slider.duration) == "number" and slider.duration > 0 and type(slider.time) == "number",
    "the time keys")
  C.expect(slider.unknownKey == nil, "an unknown key reads a value")
  C.expect(s.sliders ~= sliders and s.sliders.rotation == slider, "sliders is not a fresh table of equal wrappers")
  C.expect(#s.ikConstraints == 0, "ikConstraints lists the slider")
  local other = spine.create(data)
  C.expect(other.sliders.rotation ~= slider, "two skeletons' sliders are equal")
  C.expect(next(spine.create(spine.loadSkeletonData("spineboy/spineboy.json",
    spine.loadAtlas("spineboy/spineboy.atlas"))).sliders) == nil, "a skeleton with no slider lists one")
elseif mode == "write" then
  local s = spine.create(data)
  local slider = s.sliders.rotation
  slider.time = 0
  local middle0, top0 = pose(s)
  slider.time = slider.duration / 4
  C.expect(near(slider.time, slider.duration / 4), "the time did not read back")
  local middle1, top1 = pose(s)
  C.expect(not near(middle0, middle1) or not near(top0, top1), "a time write did not move the keyed bones")
  slider.mix = 0
  C.expect(slider.mix == 0, "the mix did not read back")
  slider.time = 0
  local middle2, top2 = pose(s)
  slider.time = slider.duration / 4
  local middle3, top3 = pose(s)
  C.expect(near(middle2, middle3) and near(top2, top3), "mix = 0 did not stop the slider")
  for _, key in ipairs({ "duration", "name", "animation", "loop", "boneDriven" }) do
    local before = slider[key]
    C.expect(raises(function() slider[key] = before end, "SpineSlider: property '" .. key .. "' is read-only"),
      key .. " write did not raise")
    C.expect(slider[key] == before, key .. " changed")
  end
  C.expect(raises(function() slider.speed = 1 end, "SpineSlider: unknown property 'speed'"), "unknown write")
  C.expect(raises(function() slider.time = "late" end, "number expected, got string)"), "a string time")
  C.expect(raises(function() slider.mix = nil end, "number expected, got nil)"), "a nil mix")
  C.expect(near(slider.time, slider.duration / 4) and slider.mix == 0, "a raised write changed the slider")
elseif mode == "detach" then
  local s = spine.create(data)
  local slider, control = s.sliders.rotation, bone(s, "diamond-rotation-control")
  control.rotation = 0
  pose(s)
  local t0 = slider.time
  control.rotation = 90
  pose(s)
  local t1 = slider.time
  C.expect(not near(t0, t1), "the bone does not drive the time")
  slider.mix = 0.5
  C.expect(slider.boneDriven == true, "a mix write detached the bone")
  slider.time = 0.25
  C.expect(slider.boneDriven == false and near(slider.time, 0.25), "a time write did not detach the bone")
  control.rotation = 180
  pose(s)
  C.expect(slider.boneDriven == false and near(slider.time, 0.25), "the detached bone still drives the time")
  C.expect(s.sliders.rotation.boneDriven == false, "a fresh wrapper reads the bone attached")
elseif mode == "removed" then
  local s = spine.create(data)
  local slider, other = s.sliders.rotation, s.sliders.rotation
  s:removeSelf(); S.frame()
  C.expect(raises(function() return slider.time end, REMOVED), "read")
  C.expect(raises(function() return slider.name end, REMOVED), "read-only read")
  C.expect(raises(function() slider.time = 1 end, REMOVED), "write")
  C.expect(raises(function() slider.name = "x" end, REMOVED), "read-only write before the lifecycle error")
  C.expect(raises(function() return slider == other end, REMOVED), "==")
  C.expect(s.sliders == nil, "a removed skeleton reads sliders")
  S.gcfull()
  C.expect(raises(function() return slider.mix end, REMOVED), "read after collectgarbage")
elseif mode == "bone" then
  local s = spine.create(data)
  local slider, control = s.sliders.rotation, bone(s, "diamond-rotation-control")
  slider.time = 0.5
  control.rotation = 45
  pose(s); s:draw()
  C.expect(slider.boneDriven == false and near(slider.time, 0.5), "the bone drives the written time")
  s:removeSelf(); S.frame()
  s = nil; data = nil; S.gcfull()
  C.expect(raises(function() return slider.time end, REMOVED), "the slider after its bone was removed")
  C.expect(raises(function() return control.rotation end, "Bone belongs to a removed skeleton"),
    "the bone after removal")
  C.expect(raises(function() slider.time = 1 end, REMOVED), "a time write after its bone was removed")
elseif mode == "sequence" then
  local a, b = spine.create(data), spine.create(data)
  local shine = a:getSlot("top-shine").attachment
  local copy = shine:copy()
  C.expect(copy ~= shine and copy.name == shine.name, "the sequence attachment's copy")
  a:getSlot("top-shine").attachment = copy
  b:getSlot("top-shine").attachment = copy
  -- scrubbed across the whole animation: the slider's sequence timeline sets the copy's frame on both slots
  for _, s in ipairs({ a, b }) do
    local slider = s.sliders.rotation
    for i = 0, 8 do
      slider.time = slider.duration * i / 8
      s:updateState(33); s:draw()
    end
  end
  C.expect(a:getSlot("top-shine").attachment == copy and b:getSlot("top-shine").attachment == copy,
    "the scrubbed slots do not show the copy")
  a:removeSelf(); S.frame(); S.gcfull()
  local slider = b.sliders.rotation
  for i = 0, 8 do
    slider.time = slider.duration * i / 8
    b:updateState(33); b:draw()
  end
  b:removeSelf(); S.frame()
  shine, a, b, data = nil, nil, nil, nil; S.gcfull()
  C.expect(copy.name == "top" and copy.type == "mesh", "the copy did not outlive both skeletons")
end
print("end of script")
C.done()
