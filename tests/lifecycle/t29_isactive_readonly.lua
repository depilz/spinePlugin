-- ikConstraint.isActive and physics.isActive are read-only: a write raises and leaves the constraint active;
-- mix = 0 (the advised way to stop one) is accepted. With "removed", the write on a removed skeleton's wrapper raises
-- the removed-skeleton error instead, in the dispose window and after the next-frame hook.
local spine = require("plugin.spine")
local S = __stub
local which, removed = arg[1], arg[2] == "removed"
local files = { ik = "spineboy/spineboy", physics = "cloud-pot/cloud-pot" }
local messages = {
  ik = "IK constraint isActive is read-only; set mix = 0 to stop it",
  physics = "Physics constraint isActive is read-only; set mix = 0 to stop it",
}
local atlas = spine.loadAtlas(files[which] .. ".atlas")
local data = spine.loadSkeletonData(files[which] .. (which == "ik" and ".json" or ".skel"), atlas)
local obj = spine.create(data)
local constraint = which == "ik" and obj.ikConstraints[1] or obj.physics
if removed then
  local dead = which == "ik" and "IK constraint belongs to a removed skeleton"
    or "Physics constraint belongs to a removed skeleton"
  obj:removeSelf(); S.endFrame()                -- the dispose window: finalized, the next frame has not begun
  S.raises(dead, function() constraint.isActive = false end)
  S.frame()                                     -- after the next-frame hook
  S.raises(dead, function() constraint.isActive = false end)
  print("survived")
  return
end
for _, value in ipairs({ false, true }) do
  local ok, err = pcall(function() constraint.isActive = value end)
  print(which, "isActive =", value, "->", ok, err)
  -- luaL_error prefixes the caller's "file:line: " position
  assert(not ok and err:sub(-#messages[which] - 2) == ": " .. messages[which], "expected the read-only error")
  assert(constraint.isActive == true, "a rejected write must leave the constraint active")
end
constraint.mix = 0
assert(constraint.mix == 0, "mix = 0 must be accepted")
obj:updateState(16); obj:draw()
print("survived")
