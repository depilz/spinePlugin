-- Spine object removed indirectly (parent group removed, as composer does with scene.view).
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1] or "parent"
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local parent = display.newGroup()
local obj = spine.create(data, function(e) end)
parent:insert(obj)
obj:setAnimation(1, "walk", true); obj:updateState(16); obj:draw()
local weak = setmetatable({}, { __mode = "v" })
weak.skel = rawget(obj, "_skeleton"); weak.obj = obj
if mode == "parent" then
  display.remove(parent)
else
  obj:removeSelf(); parent:removeSelf()
end
print("mode", mode)
print("obj metatable after removal:", getmetatable(obj))
print("obj.removeSelf after removal:", rawget(obj, "removeSelf"), "(obj is plain table:", getmetatable(obj) == nil, ")")
print("obj._skeleton still set:", rawget(obj, "_skeleton") ~= nil)
obj, data, atlas, parent = nil, nil, nil, nil
S.gcfull()
print("after dropping every Lua reference + full GC:")
print("  SpineSkeleton userdata still alive:", weak.skel ~= nil, " spine object table alive:", weak.obj ~= nil)
print("  textures created", S.texturesCreated, "released", S.texturesReleased)
