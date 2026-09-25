-- T9: the T3/T4/T7 scenarios as the reviewed prototype fix passes them (animation-2/1/3): disposed entries report
-- isValid = false and raise on access, the tracks proxy raises after removal, removal inside a callback is deferred.
local fx = require("realdata_fixture")
local C = dofile(arg[0]:match("^(.*)/") .. "/check.lua")
local data = fx.loadData("spineboy/spineboy.atlas", "spineboy/spineboy.json")

print("1) stale entry after dispose / pooled reuse")
local s = fx.createPlugin(data)
s:setDefaultMix(200)
local walk = s:setAnimation(1, "walk", true)
s:updateState(16)
local run = s:setAnimation(1, "run", true)
for i = 1, 20 do s:updateState(16) end
print("  walk.isValid", walk.isValid, "run.isValid", run.isValid)
C.expect(walk.isValid == false and run.isValid == true, "entry.isValid missing or wrong after mix-out (animation-2)")
print("  walk.animation ->", pcall(function() return walk.animation end))
print("  walk.timeScale = 0 ->", pcall(function() walk.timeScale = 0 end))
local jump = s:setAnimation(2, "jump", false) -- reuses pooled object
print("  jump.isValid", jump.isValid, "stale walk still invalid:", walk.isValid == false, "jump.animation", jump.animation)
print("  entry from setAnimation then replaced before first update:")
local a = s:setAnimation(3, "idle", true)
local b = s:setAnimation(3, "aim", true) -- 'a' never applied -> disposed immediately
print("    a.isValid", a.isValid, "b.isValid", b.isValid)
C.expect(a.isValid == false and b.isValid == true, "entry replaced before its first update still valid (animation-2)")

print("2) entry + tracks proxy after skeleton destroyed")
local e = s:getTrackEntry(1)
local tracks = s.tracks
fx.dispose(s)
print("  e.isValid", e.isValid, "e.trackTime ->", pcall(function() return e.trackTime end))
C.expect(e.isValid == false, "entry still valid after its skeleton was destroyed (animation-2)")
print("  #tracks ->", pcall(function() return #tracks end))

print("3) remove the skeleton inside 'completed' (deferred destroy)")
local s2
s2 = fx.createPlugin(data, function(ev)
  if ev.name == "spine" then print("  [listener]", ev.phase, ev.animation) end
  if ev.phase == "completed" then fx.dispose(s2); print("  -> disposed inside callback") end
end)
s2:setAnimation(1, "jump", false)
for i = 1, 100 do if rawget(s2, "_skeleton") then s2:updateState(16) end end
print("  survived; _skeleton =", rawget(s2, "_skeleton"))

print("4) remove inside 'began' fired synchronously by setAnimation")
local s3
s3 = fx.createPlugin(data, function(ev) if ev.phase == "began" then fx.dispose(s3) end end)
print("  setAnimation returned", s3:setAnimation(1, "walk", true))
print("done")
C.done()
