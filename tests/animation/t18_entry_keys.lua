-- T18: strict TrackEntry writes (D19) and wrapper equality by entry identity (D20, animation-16).
-- mode = unknown | readonly | stale | eq | recycled
local spine = require("plugin.spine")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local mode = arg[1]
local data = spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas"))
local s = spine.create(data)
local READ_ONLY = { "trackIndex", "index", "animation", "trackComplete", "isComplete", "animationTime", "next",
  "mixingFrom", "mixingTo", "isValid" }

-- raises(f, message): f raised an error ending in message
local function raises(f, message)
  local ok, err = pcall(f)
  print("  raised:", not ok, err)
  return not ok and tostring(err):sub(-#message) == message
end
-- staleWalk(): walk, stepped until it (mixed out by run) is ended and disposed (reset + returned to the pool)
local function staleWalk()
  s:setDefaultMix(200)
  local walk = s:setAnimation(1, "walk", true)
  s:updateState(16)
  s:setAnimation(1, "run", true)
  for i = 1, 20 do s:updateState(16) end -- 320 ms > 200 ms mix
  C.expect(not walk.isValid, "walk is still valid: the test proves nothing")
  return walk
end

if mode == "unknown" then
  local e = s:setAnimation(1, "walk", true)
  C.expect(raises(function() e.timescale = 2 end, "SpineTrackEntry: unknown property 'timescale'"),
    "an unknown key write did not raise the D19 message")
  C.expect(raises(function() e.setMixDuration = 1 end, "SpineTrackEntry: unknown property 'setMixDuration'"),
    "a method-name write did not raise the D19 unknown message")
  C.expect(e.timescale == nil, "an unknown key read is not nil")
  e.timeScale = 2 -- writable keys still write
  C.expect(e.timeScale == 2, "a writable key write was lost")
elseif mode == "readonly" then
  local e = s:setAnimation(1, "walk", true)
  s:addAnimation(1, "run", true, 0)
  for _, key in ipairs(READ_ONLY) do
    C.expect(raises(function() e[key] = e[key] end, ("SpineTrackEntry: property '%s' is read-only"):format(key)),
      "a read-only write did not raise the D19 message: " .. key)
  end
elseif mode == "stale" then
  local walk = staleWalk()
  local stale = "Track entry is no longer valid (finished or disposed); check entry.isValid"
  C.expect(raises(function() walk.timescale = 2 end, stale), "a stale unknown-key write did not raise L17 first")
  C.expect(raises(function() walk.index = 2 end, stale), "a stale read-only write did not raise L17 first")
  local e = s:getTrackEntry(1)
  s:removeSelf(); __stub.frame()
  C.expect(raises(function() e.timescale = 2 end, "Track entry belongs to a removed skeleton"),
    "an unknown-key write on a removed skeleton's entry did not raise L17 first")
elseif mode == "eq" then
  s:setAnimation(2, "walk", true)
  local a, b = s:getTrackEntry(2), s:getTrackEntry(2)
  C.expect(not rawequal(a, b), "getTrackEntry returned the same wrapper: the test proves nothing")
  C.expect(a == b, "getTrackEntry(2) ~= getTrackEntry(2)")
  C.expect(a == s.tracks[2], "tracks[2] ~= getTrackEntry(2)")
  local jump = s:setAnimation(1, "jump", false)
  C.expect(a ~= jump, "entries of different tracks compare equal")
  C.expect(a ~= nil and a ~= 2, "an entry compares equal to a non-entry")
  local ok, eq = pcall(function() return a == b end)
  s:removeSelf(); __stub.frame()
  local okStale, eqStale = pcall(function() return a == b end)
  print("  stale a == b:", okStale, eqStale)
  C.expect(ok and eq and okStale and eqStale, "__eq raised or changed once the skeleton was removed")
elseif mode == "recycled" then
  local walk = staleWalk()
  local walkPtr = __native.entryPtr(walk)
  local jump = s:setAnimation(2, "jump", false) -- obtains the pooled object
  C.expect(__native.entryPtr(jump) == walkPtr, "jump did not reuse walk's pooled TrackEntry: the test proves nothing")
  local ok, eq = pcall(function() return walk == jump end)
  print("  stale walk == recycled jump:", ok, eq)
  C.expect(ok and not eq, "a stale wrapper equals the recycled entry's wrapper")
  C.expect(jump == s:getTrackEntry(2), "the recycled entry's wrappers are unequal")
end
print("end of script")
C.done()
