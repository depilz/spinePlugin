-- T3: TrackEntry wrapper validity after the entry is disposed (animation-2): a stale wrapper must raise or read nil,
-- never reach the freed or pooled entry. Stale accesses run in pcall so a raising fix completes the script.
-- mode = "numeric" | "animation" | "alias" | "afterdestroy" | "listener_entry"
local fx = require("realdata_fixture")
local C = dofile(arg[0]:match("^(.*)/") .. "/check.lua")
local mode = arg[1]
local data = fx.loadData("spineboy/spineboy.atlas", "spineboy/spineboy.json")
local s = fx.createPlugin(data, function(ev)
  if ev.name == "spine" and ev.phase ~= "began" then print("  [listener]", ev.phase, ev.animation) end
end)
s:setDefaultMix(200)

local walk = s:setAnimation(1, "walk", true)
print("walk entry ptr", fx.entryPtr(walk), "animation", walk.animation)
s:updateState(16)
local run = s:setAnimation(1, "run", true)
print("run entry ptr", fx.entryPtr(run))
for i = 1, 20 do s:updateState(16) end -- 320ms > 200ms mix: walk is ended + disposed (reset + returned to pool)
print("after mix: run.mixingFrom =", run.mixingFrom)

-- stale(entry, key): pcall-reads entry[key], prints it, and checks it raised or read nil
local function stale(entry, key)
  local ok, v = pcall(function() return entry[key] end)
  print(("stale %s ->"):format(key), ok, v)
  C.expect(not ok or v == nil, ("stale TrackEntry read %s = %s (animation-2)"):format(key, tostring(v)))
end

if mode == "numeric" then
  stale(walk, "trackTime"); stale(walk, "loop"); stale(walk, "index")
  local ok = pcall(function() walk.timeScale = 3 end) -- writes into pooled object
  print("stale write ok =", ok)
  C.expect(not ok, "stale TrackEntry write accepted (silently into pooled memory) (animation-2)")
elseif mode == "animation" then
  io.stdout:flush()
  stale(walk, "animation") -- TrackEntry::reset() set _animation = NULL -> getAnimation()->getName()
elseif mode == "alias" then
  local jump = s:setAnimation(2, "jump", false) -- obtains the pooled object
  print("jump entry ptr", fx.entryPtr(jump), "same object as stale walk wrapper:", fx.entryPtr(jump) == fx.entryPtr(walk))
  stale(walk, "animation"); stale(walk, "index")
  pcall(function() walk.timeScale = 0 end) -- user thinks they're pausing the old walk entry...
  for i = 1, 10 do s:updateState(16) end
  print("jump.trackTime after 160ms:", jump.trackTime, "(0 = frozen because stale 'walk' write hit jump)")
  C.expect(jump.trackTime > 0, "stale walk.timeScale = 0 froze jump (animation-2)")
elseif mode == "afterdestroy" then
  local e = s:getTrackEntry(1)
  fx.dispose(s) -- ~SpineSkeleton -> delete state -> ~AnimationState deletes entries + pool
  print("entry after skeleton destroyed ->")
  io.stdout:flush()
  stale(e, "trackTime")
elseif mode == "listener_entry" then
  -- getTrackEntry during 'disposed' then use later
  local kept
  s:setListener(function(ev) if ev.phase == "disposed" then kept = s:getTrackEntry(ev.trackIndex) end end)
  s:setAnimation(1, "idle", true)
  for i = 1, 20 do s:updateState(16) end
  print("kept (current entry grabbed during dispose)", kept and kept.animation)
end
print("end of script")
C.done()
