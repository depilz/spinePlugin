-- obj:removeSelf() removes the meshes it drew into the caller's split group through each mesh's own removeSelf, which
-- a user can override: the override re-enters the skeleton (a cached draw, split or reassemble) mid-removal. The
-- removed skeleton must not draw, split or reassemble again, and every split mesh is removed exactly once.
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1] or "draw"
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local scene = display.newGroup()
local obj = spine.create(data); scene:insert(obj)
-- hoverboard shows the additive glows: the split group holds several meshes (blend changes)
obj:setAnimation(1, "hoverboard", true); obj:updateState(500)
local splitGroup = obj:split({ "head", "side-glow1", "hoverglow-front", "hoverboard-board" })
scene:insert(splitGroup)
obj:draw()

-- methods cached before removal: indexing a removed object no longer reaches them
local reenter = ({
  draw = function() return obj.draw end,
  split = function() local split = obj.split; return function(o) return split(o, { "head" }) end end,
  reassemble = function() return obj.reassemble end,
})[mode]
assert(reenter, "unknown mode " .. tostring(mode))
reenter = reenter()

local meshes, removals, results = {}, {}, {}
for _, mesh in ipairs(S.children(splitGroup)) do
  meshes[#meshes + 1] = mesh
  local original = mesh.removeSelf
  rawset(mesh, "removeSelf", function(self)
    removals[self] = (removals[self] or 0) + 1
    results[#results + 1] = { pcall(reenter, obj) }
    return original(self)
  end)
end
print("split meshes:", #meshes)
assert(#meshes > 1, "the split group holds fewer than two meshes")

local created, updates = S.meshesCreated, S.meshUpdates
assert(pcall(function() obj:removeSelf() end), "obj:removeSelf() raised")
for i, r in ipairs(results) do
  print("re-entrant " .. mode .. " " .. i .. ":", r[1], r[2])
  assert(r[1] and r[2] == nil, "re-entrant " .. mode .. " did not return nothing")
end
assert(#results == #meshes, "expected one re-entry per split mesh, got " .. #results)
assert(S.meshesCreated == created and S.meshUpdates == updates, "the removed skeleton drew")
for i, mesh in ipairs(meshes) do
  assert(removals[mesh] == 1, "split mesh " .. i .. " removed " .. tostring(removals[mesh]) .. " times")
end

S.frame()
print("split group alive:", not S.isRemoved(splitGroup), "children:", S.children(splitGroup) and #S.children(splitGroup))
assert(not S.isRemoved(splitGroup), "the caller's split group was removed")
assert(#S.children(splitGroup) == 0, "split meshes left in the caller's group")
for i, mesh in ipairs(meshes) do assert(S.isRemoved(mesh), "split mesh " .. i .. " not finalized") end
S.gcfull(); S.frame(); S.gcfull()
print("ok")
