-- T5: addAnimationAt semantics (actual start times vs requested "absolute" times).
local fx = require("realdata_fixture")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local data = fx.loadData("spineboy/spineboy.atlas", "spineboy/spineboy.json")
local clock, began = 0, {}
local function mk()
  clock, began = 0, {}
  return fx.createPlugin(data, function(ev)
    if ev.name == "spine" and ev.phase == "began" then began[ev.animation] = clock; print(("    began %-8s at t=%4dms"):format(ev.animation, clock)) end
  end)
end
local function run(s, ms) for i = 1, ms / 10 do s:updateState(10); clock = clock + 10 end end

print("A) doc example shape: idle(loop) + addAnimationAt walk@1200, run@1800")
local s = mk()
s:setAnimation(1, "idle", true)
s:addAnimationAt(1, "walk", false, 1200)
s:addAnimationAt(1, "run", false, 1800)
run(s, 2500)

print("B) same, but the second call happens after the queue advanced (t=1300)")
s = mk()
s:setAnimation(1, "idle", true)
s:addAnimationAt(1, "walk", false, 1200)
run(s, 1300)
s:addAnimationAt(1, "run", false, 1800)
run(s, 2500)

print("C) out-of-order calls: run@1200 then jump@1000 (clamped delay 0 => 'after previous completes')")
s = mk()
s:setAnimation(1, "idle", true)
s:addAnimationAt(1, "run", false, 1200)
local okJump = pcall(s.addAnimationAt, s, 1, "jump", false, 1000)
run(s, 3500)
-- the fix either rejects the earlier time or starts jump right after run, never after run completes
C.expect(not okJump or began.jump <= began.run + 20,
  ("jump@1000 queued after run@1200 began at %sms, after run completed (animation-10)"):format(tostring(began.jump)))

print("D) empty track, startTime 500: inserts an <empty> entry (visible to listener)")
s = mk()
s:setDefaultMix(200)
local e = s:addAnimationAt(1, "walk", false, 500)
print("    returned entry mixDuration", e.mixDuration, "delay", e.delay)
run(s, 800)

print("E) called 700ms into the current entry: startTime 1000 is relative to the current entry's start, not 'now'")
s = mk()
s:setAnimation(1, "idle", true)
run(s, 700)
s:addAnimationAt(1, "walk", false, 1000)
run(s, 1000)

print("F) with skeleton timeScale 2 (startTime measured in unscaled track time)")
s = mk()
s.timeScale = 2
s:setAnimation(1, "idle", true)
s:addAnimationAt(1, "walk", false, 1000)
run(s, 1000)
print("done")
C.done()
