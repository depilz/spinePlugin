-- T6: addAnimation delay semantics vs docs; mixDuration vs setMixDuration(mix, delay);
--     'ended' vs 'completed' for a non-looping animation (Solar2D sprite users expect 'ended').
local fx = require("realdata_fixture")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local data = fx.loadData("spineboy/spineboy.atlas", "spineboy/spineboy.json")
local clock = 0
local function mk(filter)
  clock = 0
  return fx.createPlugin(data, function(ev)
    if ev.name == "spine" and (not filter or filter[ev.phase]) then print(("    %-11s %-6s at t=%4dms"):format(ev.phase, ev.animation, clock)) end
  end)
end
local function run(s, ms) for i = 1, ms / 10 do s:updateState(10); clock = clock + 10 end end

print("A) docs: 'hero:addAnimation(1, \"run\", true, 200) -- queue run afterward, delayed by 200ms' (walk is 1067ms)")
local s = mk({began = true})
s:setAnimation(1, "walk", true)
s:addAnimation(1, "run", true, 200)
run(s, 1500)

print("B) addAnimation delay 0 => start at previous completion minus mix (default mix 300)")
s = mk({began = true})
s:setDefaultMix(300)
s:setAnimation(1, "walk", false)
local e = s:addAnimation(1, "run", true, 0)
print("    queued delay", e.delay, "mixDuration", e.mixDuration)
e.mixDuration = 0  -- property setter: does NOT recompute delay
print("    after entry.mixDuration = 0: delay", e.delay)
e:setMixDuration(0, 0) -- 4.2 two-arg form recomputes delay
print("    after entry:setMixDuration(0, 0): delay", e.delay)
run(s, 1300)

print("C) non-looping 'jump' finishing: which phases fire? (no replacement)")
s = mk()
s:setAnimation(1, "jump", false)
run(s, 2500)
print("    still current after finishing:", s:getCurrentAnimation(1), "isComplete", s:getTrackEntry(1).isComplete)
print("D) same with addEmptyAnimation(1, 200, 0) queued => 'ended' fires")
s = mk()
s:setAnimation(1, "jump", false)
s:addEmptyAnimation(1, 200, 0)
run(s, 2500)
print("    current:", s:getCurrentAnimation(1), "isActive", s.isActive)
C.expect(s:getCurrentAnimation(1) ~= nil or s.isActive == false, "isActive stays true with no current animation (animation-15)")
print("done")
C.done()
