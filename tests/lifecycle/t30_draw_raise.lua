-- An injection listener that raises inside draw(): the error still reaches the caller (D4), and draw's call guard
-- is released on the way out, so a later removal still disposes the skeleton at the end of the frame.
local spine = require("plugin.spine")
local S = __stub
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local weak = setmetatable({}, { __mode = "v" })
weak.listener = function(e) end
local obj = spine.create(data, weak.listener)
local parent = display.newGroup(); parent:insert(obj)
obj:setAnimation(1, "walk", true); obj:updateState(16)
obj:inject(display.newGroup(), "head", function() error("injection listener boom") end)
local ok, err = pcall(obj.draw, obj)
print("draw with a raising injection listener ->", ok, err)
assert(not ok and tostring(err):find("injection listener boom", 1, true), "the injection listener error must propagate out of draw()")
-- keep the userdata alive, so only dispose() (not __gc) can release the animation listener; removal through the
-- parent reaches the skeleton by its finalize listener, not the plugin's removeSelf
local skel = rawget(obj, "_skeleton")
display.remove(parent)
S.frame()
S.gcfull()
print("after removal + frame: animation listener released", weak.listener == nil, "userdata held", skel ~= nil)
assert(weak.listener == nil, "the skeleton was not disposed on removal: draw's call guard is still held")
