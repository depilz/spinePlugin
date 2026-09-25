-- T7: s.tracks proxy outliving the skeleton (animation-3): #tracks after dispose must raise or read 0, never reach
-- the freed AnimationState.
local fx = require("realdata_fixture")
local C = dofile(arg[0]:match("^(.*)/") .. "/check.lua")
local data = fx.loadData("spineboy/spineboy.atlas", "spineboy/spineboy.json")
local s = fx.createPlugin(data)
s:setAnimation(1, "walk", true)
local tracks = s.tracks
print("#tracks before dispose", #tracks)
fx.dispose(s)
print("#tracks after dispose ->")
io.stdout:flush()
local ok, n = pcall(function() return #tracks end)
print(ok, n)
C.expect(not ok or n == 0, "#tracks after dispose = " .. tostring(n) .. " (animation-3)")
print("end of script")
C.done()
