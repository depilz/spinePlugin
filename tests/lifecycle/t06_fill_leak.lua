-- Every obj.fill access creates a SpineFill userdata that registry-references itself.
local spine = require("plugin.spine")
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj = spine.create(data)
local weak = setmetatable({}, { __mode = "k" })
local weakBone = setmetatable({}, { __mode = "k" })
for i = 1, 1000 do
  weak[obj.fill] = true            -- e.g. obj.fill.a = 0.5 in an enterFrame fade
  weakBone[obj:getSlot("head")] = true
end
collectgarbage(); collectgarbage()
local n, m = 0, 0
for _ in pairs(weak) do n = n + 1 end
for _ in pairs(weakBone) do m = m + 1 end
print("SpineFill userdata still alive after GC:", n, "(of 1000)")
print("SpineSlot userdata still alive after GC:", m, "(of 1000, control)")
local kb = collectgarbage("count")
for i = 1, 100000 do local f = obj.fill end
collectgarbage(); collectgarbage()
print(string.format("Lua heap growth after 100k more obj.fill reads: %.0f KB", collectgarbage("count") - kb))
