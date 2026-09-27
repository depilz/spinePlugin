-- ikConstraint.isActive and physics.isActive are read-only: a write raises and leaves the constraint active;
-- mix = 0 (the advised way to stop one) is accepted.
local spine = require("plugin.spine")
local which = arg[1]
local files = { ik = "spineboy/spineboy", physics = "cloud-pot/cloud-pot" }
local messages = {
  ik = "IK constraint isActive is read-only; set mix = 0 to stop it",
  physics = "Physics constraint isActive is read-only; set mix = 0 to stop it",
}
local atlas = spine.loadAtlas(files[which] .. ".atlas")
local data = spine.loadSkeletonData(files[which] .. (which == "ik" and ".json" or ".skel"), atlas)
local obj = spine.create(data)
local constraint = which == "ik" and obj.ikConstraints[1] or obj.physics
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
