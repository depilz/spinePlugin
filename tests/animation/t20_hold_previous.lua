-- T20: trackEntry.holdPrevious, removed on 4.3 (I14 D14) and still read and written on 4.2 (A8).
-- mode = readwrite | removed | stale
--   readwrite  (4.2) a bool, false by default, and each write reads back
--   removed    (4.3) reading and writing it raise the D14 message; the entry's other keys still work
--   stale      (4.3) on an entry no longer valid, or of a removed skeleton, the L17 message comes first
local spine = require("plugin.spine")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local mode = arg[1]
local data = spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas"))
local s = spine.create(data)
local REMOVED = "SpineTrackEntry: property 'holdPrevious' was removed in Spine 4.3; use additive or mixInterpolation"

-- raises(f, message): f raised an error ending in message
local function raises(f, message)
  local ok, err = pcall(f)
  print("  raised:", not ok, err)
  return not ok and tostring(err):sub(-#message) == message
end
-- holdRaises(e, message): reading and writing e.holdPrevious each raised message
local function holdRaises(e, message, what)
  C.expect(raises(function() return e.holdPrevious end, message), "a read of " .. what .. " did not raise " .. message)
  C.expect(raises(function() e.holdPrevious = true end, message), "a write of " .. what .. " did not raise " .. message)
end

if mode == "readwrite" then
  local e = s:setAnimation(1, "walk", true)
  C.expect(e.holdPrevious == false, "a new entry holds the previous one")
  e.holdPrevious = true
  C.expect(e.holdPrevious == true, "holdPrevious = true did not read back")
  e.holdPrevious = false
  C.expect(e.holdPrevious == false, "holdPrevious = false did not read back")
elseif mode == "removed" then
  local e = s:setAnimation(1, "walk", true)
  holdRaises(e, REMOVED, "a valid entry")
  e.alpha = 0.5 -- the entry is untouched
  C.expect(e.alpha == 0.5 and e.isValid, "the entry changed after the raises")
elseif mode == "stale" then
  s:setDefaultMix(200)
  local walk = s:setAnimation(1, "walk", true)
  s:updateState(16)
  s:setAnimation(1, "run", true)
  for _ = 1, 20 do s:updateState(16) end -- 320 ms > 200 ms mix
  C.expect(not walk.isValid, "walk is still valid: the test proves nothing")
  holdRaises(walk, "Track entry is no longer valid (finished or disposed); check entry.isValid", "a stale entry")
  local e = s:getTrackEntry(1)
  s:removeSelf(); __stub.frame()
  holdRaises(e, "Track entry belongs to a removed skeleton", "a removed skeleton's entry")
end
print("end of script")
C.done()
