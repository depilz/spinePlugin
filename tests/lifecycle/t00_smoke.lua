local spine = require("plugin.spine")
local S = __stub
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local events = {}
local obj = spine.create(data, function(e) events[#events+1] = (e.phase or e.name) .. ":" .. tostring(e.animation) end)
print("type(obj)", type(obj), "parent is stage", obj.parent == display.getCurrentStage())
print("setAnimation ->", type(obj:setAnimation(1, "walk", true)))
obj:updateState(16); obj:draw()
print("meshes created", S.meshesCreated, "children of obj", #S.children(obj), "textures", S.texturesCreated)
for i = 1, 100 do obj:updateState(16); obj:draw() end
print("events", #events, events[1], events[2])
obj:removeSelf()
S.frame()
print("after removeSelf: finalized", S.finalized, "metatable is group mt?", getmetatable(obj) ~= nil)
obj = nil; data = nil; atlas = nil
S.gcfull()
print("textures created", S.texturesCreated, "released", S.texturesReleased)
