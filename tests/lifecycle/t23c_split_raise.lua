-- obj:removeSelf() calls each split mesh's own removeSelf, which a user can override to raise: the raise reaches the
-- caller, and the mesh it interrupted must not stay referenced from the registry (C93: the plugin held it in a C++
-- holder whose unref the error jumped over). Once the scene is removed and collected, no split mesh is left alive.
local spine = require("plugin.spine")
local S = __stub
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local scene = display.newGroup()
local obj = spine.create(data); scene:insert(obj)
local splitGroup = obj:split({ "head", "eye", "mouth" })
scene:insert(splitGroup)
obj:draw()

-- the first split mesh removeSelf reaches raises; the others remove normally
local alive = setmetatable({}, { __mode = "k" })
local raised = false
for _, mesh in ipairs(S.children(splitGroup)) do
  alive[mesh] = true
  local original = mesh.removeSelf
  rawset(mesh, "removeSelf", function(self)
    if raised then return original(self) end
    raised = true
    error("user removeSelf raised")
  end)
end
assert(next(alive), "the split group holds no meshes")

S.raises("user removeSelf raised", function() obj:removeSelf() end)
scene:removeSelf()
obj, splitGroup, scene = nil, nil, nil
S.frame(); S.gcfull(); S.frame(); S.gcfull()

local left = 0
for _ in pairs(alive) do left = left + 1 end
print("split meshes alive after the scene was collected:", left)
assert(left == 0, left .. " split mesh(es) still referenced after removal")
print("ok")
