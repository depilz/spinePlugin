-- T1: basic animation-control surface: return values, units, 1-based indices, tracks snapshot.
local spine = require("plugin.spine")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local data = spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas"))
local s = spine.create(data)

local anims = s:getAnimations()
print("animations:", table.concat(anims, ","))
print("findAnimation('run') ->", s:findAnimation("run"), " findAnimation('nope') ->", s:findAnimation("nope"))
print("setAnimation unknown ->", s:setAnimation(1, "nope", true))
print("addAnimation unknown ->", s:addAnimation(1, "nope", true, 0))

local e = s:setAnimation(1, "run", true)
print("setAnimation returns", type(e), "index", e.index, "animation", e.animation, "loop", e.loop)
print("animationEnd(ms)", e.animationEnd, "trackEnd", e.trackEnd, "mixDuration", e.mixDuration, "timeScale", e.timeScale)
print("isActive", s.isActive, "timeScale", s.timeScale)
C.expect(s.isActive == true, "isActive false while an animation is current")

-- tracks snapshot (D18)
local t = s.tracks
print("type(s.tracks)", type(t), "#tracks", #t, "tracks[1].animation", t[1] and t[1].animation)
C.expect(type(t) == "table" and #t == 1 and t[1].animation == "run", "tracks is not {run entry}")
print("ipairs(s.tracks):", pcall(function() for i, tr in ipairs(s.tracks) do print("  ", i, tr.animation) end end))
print("pairs(s.tracks):", pcall(function() for k, v in pairs(s.tracks) do print("  ", k, v and v.animation) end end))
print("tracks.foo:", t.foo, " tracks[0]:", t[0])

-- only track 3 set: sparse
local s2 = spine.create(data)
s2:setAnimation(3, "walk", true)
print("sparse: #tracks", #s2.tracks, "tracks[1]", s2.tracks[1], "tracks[3]", s2.tracks[3] and s2.tracks[3].animation)
C.expect(#s2.tracks == 3 and s2.tracks[1] == false and s2.tracks[3].animation == "walk", "sparse tracks")
print("sparse: getCurrentAnimation()", s2:getCurrentAnimation(), "getCurrentAnimation(3)", s2:getCurrentAnimation(3))
C.expect(s2.isActive == true, "isActive false with only track 3 current")

-- 0-based misuse
print("setAnimation(0,...) ->", pcall(s.setAnimation, s, 0, "run", true))
print("getTrackEntry(0) ->", pcall(s.getTrackEntry, s, 0))
print("getCurrentAnimation(0) ->", pcall(s.getCurrentAnimation, s, 0))
print("clearTrack(0) ->", pcall(s.clearTrack, s, 0))
print("setAnimation(1.7,...) index ->", (s:setAnimation(1.7, "run", true)).index)

-- isActive after clearTrack
local s3 = spine.create(data)
s3:setAnimation(1, "run", true)
s3:clearTrack(1)
print("after clearTrack(1): isActive", s3.isActive, "#tracks", #s3.tracks, "raw", __native.rawTrackCount(s3), "getTrackEntry(1)", s3:getTrackEntry(1))
C.expect(s3.isActive == false, "isActive stays true after clearTrack(1) (animation-15)")
s3:setAnimation(1, "jump", false)
for i = 1, 200 do s3:updateState(16) end
print("after non-looping anim ended: isActive", s3.isActive, "getCurrentAnimation", s3:getCurrentAnimation(1), "#tracks", #s3.tracks)
C.expect(s3.isActive == true, "isActive false while a finished non-looping animation is still current")
s3:clearTracks()
print("after clearTracks: isActive", s3.isActive, "#tracks", #s3.tracks)
C.expect(s3.isActive == false, "isActive true after clearTracks")

-- units
local s4 = spine.create(data)
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
for _, write in ipairs({ { "mixBlend", "add" }, { "aplha", 0.5 }, { "animation", "walk" }, { "index", 7 } }) do
  local key = write[1]
  local ok, err = pcall(function() e5[key] = write[2] end)
  print("bogus write", key, "raised:", not ok, err)
  C.expect(not ok, "a write to unknown/read-only entry key " .. key .. " was accepted (D19)")
end
print("after bogus writes: mixBlend", e5.mixBlend, "aplha", e5.aplha, "animation", e5.animation, "index", e5.index, "alpha", e5.alpha)
print("unsupported getters: previous", e5.previous, "wasApplied", e5.wasApplied, "mixBlend", e5.mixBlend)
print("tostring(entry)", tostring(e5):match("^%a+"))
print("entry equality: getTrackEntry(2)==getTrackEntry(2)", s4:getTrackEntry(2) == s4:getTrackEntry(2))
C.expect(s4:getTrackEntry(2) == s4:getTrackEntry(2), "getTrackEntry(2) ~= getTrackEntry(2) (D20)")
print("done")
C.done()
