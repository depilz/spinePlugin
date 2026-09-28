-- gap-6 g4: setAnimation whose synchronous 'began' callback removes the object.
local spine = require("plugin.spine")
local S = __stub
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj = spine.create(data)
obj:setAnimation(1, "walk", true); obj:updateState(16)
obj:setListener(function(e) if e.phase == "began" and e.animation == "run" then obj:removeSelf() end end)
local r = obj:setAnimation(1, "run", true)
print("setAnimation returned", type(r), "obj.removeSelf after removal:", obj.removeSelf)
assert(obj.removeSelf == nil, "a removed object still answers removeSelf")
assert(r == nil or r.isValid == false, "setAnimation returned a live entry of a removed object")
S.frame(); S.gcfull()
