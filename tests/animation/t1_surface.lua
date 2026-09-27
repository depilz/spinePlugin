-- T1: basic animation-control surface: return values, units, 1-based indices, tracks proxy.
local fx = require("realdata_fixture")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local data = fx.loadData("spineboy/spineboy.atlas", "spineboy/spineboy.json")
local s = fx.createPlugin(data)

local anims = s:getAnimations()
print("animations:", table.concat(anims, ","))
print("findAnimation('run') ->", s:findAnimation("run"), " findAnimation('nope') ->", s:findAnimation("nope"))
print("setAnimation unknown ->", s:setAnimation(1, "nope", true))
print("addAnimation unknown ->", s:addAnimation(1, "nope", true, 0))

local e = s:setAnimation(1, "run", true)
print("setAnimation returns", type(e), "index", e.index, "animation", e.animation, "loop", e.loop)
print("animationEnd(ms)", e.animationEnd, "trackEnd", e.trackEnd, "mixDuration", e.mixDuration, "timeScale", e.timeScale)
print("isActive", s.isActive, "timeScale", s.timeScale)

-- tracks proxy
local t = s.tracks
print("type(s.tracks)", type(t), "#tracks", #t, "tracks[1].animation", t[1] and t[1].animation)
print("ipairs(s.tracks):", pcall(function() for i, tr in ipairs(s.tracks) do print("  ", i, tr.animation) end end))
print("pairs(s.tracks):", pcall(function() for k, v in pairs(s.tracks) do print("  ", k, v) end end))
print("tracks.foo:", t.foo, " tracks[0]:", t[0])

-- only track 3 set: sparse
local s2 = fx.createPlugin(data)
s2:setAnimation(3, "walk", true)
print("sparse: #tracks", #s2.tracks, "tracks[1]", s2.tracks[1], "tracks[3]", s2.tracks[3] and s2.tracks[3].animation)
print("sparse: getCurrentAnimation()", s2:getCurrentAnimation(), "getCurrentAnimation(3)", s2:getCurrentAnimation(3))

-- 0-based misuse
print("setAnimation(0,...) ->", pcall(s.setAnimation, s, 0, "run", true))
print("getTrackEntry(0) ->", pcall(s.getTrackEntry, s, 0))
print("getCurrentAnimation(0) ->", pcall(s.getCurrentAnimation, s, 0))
print("clearTrack(0) ->", pcall(s.clearTrack, s, 0))
print("setAnimation(1.7,...) index ->", (s:setAnimation(1.7, "run", true)).index)

-- isActive after clearTrack
local s3 = fx.createPlugin(data)
s3:setAnimation(1, "run", true)
s3:clearTrack(1)
print("after clearTrack(1): isActive", s3.isActive, "#tracks", #s3.tracks, "raw", fx.rawTrackCount(s3), "getTrackEntry(1)", s3:getTrackEntry(1))
C.expect(s3.isActive == false, "isActive stays true after clearTrack(1) (animation-15)")
s3:setAnimation(1, "jump", false)
for i = 1, 200 do s3:updateState(16) end
print("after non-looping anim ended: isActive", s3.isActive, "getCurrentAnimation", s3:getCurrentAnimation(1), "#tracks", #s3.tracks)
s3:clearTracks()
print("after clearTracks: isActive", s3.isActive, "#tracks", #s3.tracks)

-- units
local s4 = fx.createPlugin(data)
s4:setDefaultMix(250)
s4:setMix("walk", "run", 400)
s4:setAnimation(1, "walk", true)
s4:updateState(16)
local r = s4:setAnimation(1, "run", true)
print("mixDuration from setMix(walk,run,400) =", r.mixDuration)
local j = s4:addAnimation(1, "jump", false, 0)
print("default mix via addAnimation =", j.mixDuration, "delay(ms)", j.delay)
s4.timeScale = 2
print("skeleton timeScale", s4.timeScale)
r.timeScale = 0.5
print("entry timeScale", r.timeScale)

-- empty animation return values
print("setEmptyAnimation returns:", s4:setEmptyAnimation(1, 100))
print("addEmptyAnimation returns:", s4:addEmptyAnimation(1, 100, 0))
print("setEmptyAnimations returns:", s4:setEmptyAnimations(100))
print("getTrackEntry(1).animation", s4:getTrackEntry(1).animation)

-- unknown / read-only keys on entry
local e5 = s4:setAnimation(2, "run", true)
e5.mixBlend = "add"; e5.aplha = 0.5; e5.animation = "walk"; e5.index = 7
print("after bogus writes: mixBlend", e5.mixBlend, "aplha", e5.aplha, "animation", e5.animation, "index", e5.index, "alpha", e5.alpha)
print("unsupported getters: previous", e5.previous, "wasApplied", e5.wasApplied, "mixBlend", e5.mixBlend)
print("tostring(entry)", tostring(e5):match("^%a+"))
print("entry equality: getTrackEntry(2)==getTrackEntry(2)", s4:getTrackEntry(2) == s4:getTrackEntry(2))
print("done")
C.done()
