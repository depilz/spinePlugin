-- T5: addAnimationAt semantics (actual start times vs requested "absolute" times).
local spine = require("plugin.spine")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local data = spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas"))
local clock, began = 0, {}
local function mk()
  clock, began = 0, {}
  return spine.create(data, function(ev)
    if ev.name == "spine" and ev.phase == "began" then began[ev.animation] = clock; print(("    began %-8s at t=%4dms"):format(ev.animation, clock)) end
  end)
end
local function run(s, ms) for i = 1, ms / 10 do s:updateState(10); clock = clock + 10 end end
-- The recorded start times (both lines, 10 ms updates): the origin is the start of the entry current on the track.
local function expectBegan(case, want)
  for name, t in pairs(want) do
    C.expect(began[name] == t, ("%s: %s began at %sms, recorded %dms"):format(case, name, tostring(began[name]), t))
  end
end

print("A) doc example shape: idle(loop) + addAnimationAt walk@1200, run@1800")
local s = mk()
s:setAnimation(1, "idle", true)
s:addAnimationAt(1, "walk", false, 1200)
s:addAnimationAt(1, "run", false, 1800)
run(s, 2500)
expectBegan("A", { idle = 0, walk = 1210, run = 1810 })

print("B) same, but the second call happens after the queue advanced (t=1300)")
s = mk()
s:setAnimation(1, "idle", true)
s:addAnimationAt(1, "walk", false, 1200)
run(s, 1300)
s:addAnimationAt(1, "run", false, 1800)
run(s, 2500)
expectBegan("B", { idle = 0, walk = 1210, run = 3010 })

print("C) out-of-order calls: run@1200 then jump@1000 (delay <= 0 clamped to FLT_MIN => the update after run starts)")
s = mk()
s:setAnimation(1, "idle", true)
s:addAnimationAt(1, "run", false, 1200)
local okJump = pcall(s.addAnimationAt, s, 1, "jump", false, 1000)
run(s, 3500)
-- measured on both lines: jump starts one 10 ms update after run, never after run completes (1870ms before the clamp)
C.expect(okJump and began.run == 1210 and began.jump == began.run + 10,
  ("jump@1000 queued after run@1200 began at %sms, run at %sms (animation-10)"):format(tostring(began.jump), tostring(began.run)))

print("D) empty track, startTime 500: inserts an <empty> entry (visible to listener)")
s = mk()
s:setDefaultMix(200)
local e = s:addAnimationAt(1, "walk", false, 500)
print("    returned entry mixDuration", e.mixDuration, "delay", e.delay)
C.expect(e.mixDuration == 200 and e.delay == 500, "D: walk entry mixDuration/delay not 200/500")
run(s, 800)
expectBegan("D", { ["<empty>"] = 0, walk = 510 })

print("E) called 700ms into the current entry: startTime 1000 is relative to the current entry's start, not 'now'")
s = mk()
s:setAnimation(1, "idle", true)
run(s, 700)
s:addAnimationAt(1, "walk", false, 1000)
run(s, 1000)
expectBegan("E", { idle = 0, walk = 1010 })

print("F) with skeleton timeScale 2 (startTime measured in unscaled track time)")
s = mk()
s.timeScale = 2
s:setAnimation(1, "idle", true)
s:addAnimationAt(1, "walk", false, 1000)
run(s, 1000)
expectBegan("F", { idle = 0, walk = 510 })
print("done")
C.done()
