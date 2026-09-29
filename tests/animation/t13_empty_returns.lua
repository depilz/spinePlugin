-- T13: setEmptyAnimation/addEmptyAnimation return their TrackEntry; setEmptyAnimations returns nothing (D17).
-- mode = "returns" | "dispose" (a listener removes the object while setEmptyAnimation runs: nothing is returned)
local spine = require("plugin.spine")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local mode = arg[1]
local data = spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas"))

if mode == "returns" then
  local s = spine.create(data)
  s:setAnimation(1, "walk", true)
  s:updateState(16)
  local set = s:setEmptyAnimation(1, 100)
  print("setEmptyAnimation ->", type(set), set and set.animation, set and set.index, set and set.mixDuration)
  C.expect(type(set) == "userdata", "setEmptyAnimation returned " .. type(set))
  C.expect(set.animation == "<empty>" and set.index == 1, "setEmptyAnimation entry is not the empty entry on track 1")
  C.expect(math.abs(set.mixDuration - 100) < 1e-3, "setEmptyAnimation entry mixDuration " .. set.mixDuration)
  C.expect(__native.entryPtr(set) == __native.entryPtr(s:getTrackEntry(1)), "setEmptyAnimation entry is not current")

  local added = s:addEmptyAnimation(1, 200, 300)
  print("addEmptyAnimation ->", type(added), added and added.animation, added and added.delay, added and added.mixDuration)
  C.expect(type(added) == "userdata", "addEmptyAnimation returned " .. type(added))
  C.expect(added.animation == "<empty>" and added.index == 1, "addEmptyAnimation entry is not an empty entry on track 1")
  C.expect(math.abs(added.mixDuration - 200) < 1e-3, "addEmptyAnimation entry mixDuration " .. added.mixDuration)
  C.expect(__native.entryPtr(added) == __native.entryPtr(set.next), "addEmptyAnimation entry is not queued after current")
  added.timeScale = 2 -- the wrapper is live: writes reach the queued entry
  C.expect(set.next.timeScale == 2, "write through the addEmptyAnimation entry was lost")

  local n = select("#", s:setEmptyAnimations(100))
  print("setEmptyAnimations returns", n, "values")
  C.expect(n == 0, "setEmptyAnimations returned " .. n .. " values")
elseif mode == "dispose" then
  local s
  s = spine.create(data, function(ev)
    if ev.phase == "began" and ev.animation == "<empty>" then print("  -> removing skeleton inside 'began'"); s:removeSelf() end
  end)
  s:setAnimation(1, "walk", true)
  s:updateState(16)
  local n = select("#", s:setEmptyAnimation(1, 100))
  print("setEmptyAnimation after removal returns", n, "values")
  C.expect(n == 0, "setEmptyAnimation handed out an entry of a removed object")
  __stub.frame()
end
print("end of script")
C.done()
