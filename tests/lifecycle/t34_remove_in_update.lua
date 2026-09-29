-- A 'began' listener that removes the skeleton from inside updateState: a queued entry starts in state->update(), whose
-- drain fires 'began' before apply(). "removed": apply() must not run after the removal, so a bone wrapper held from
-- before still reads, in the same frame, the local pose it had before that updateState. "control": the same tick
-- without removal writes walk's first pose, so the bone's rotation changes (idle does not key rear-foot-target,
-- walk keys it at -32.82 at t=0).
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1]
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj
local began = false
obj = spine.create(data, function(e)
  if e.phase == "began" and e.animation == "walk" and not began then
    began = true
    if mode == "removed" then obj:removeSelf() end
  end
end)
obj:setAnimation(1, "idle", false)
obj:addAnimation(1, "walk", false, 0.05)
obj:updateState(16); obj:draw()
local bone
for _, b in ipairs(obj.bones) do if b.name == "rear-foot-target" then bone = b end end
assert(bone, "spineboy has no rear-foot-target bone")

local before
for _ = 1, 20 do
  before = bone.rotation
  obj:updateState(16)
  if began then break end
end
assert(began, "walk never began inside updateState")
local after = bone.rotation
print(mode, "rotation before", before, "after", after)
if mode == "removed" then
  assert(after == before, "apply() wrote the pose of a skeleton removed in state->update(): " .. before .. " -> " .. after)
  S.endFrame(); S.frame()
else
  assert(after ~= before, "control: the walk tick did not change the local rotation, the observable is blind")
end
print("survived")
