-- Common Solar2D pattern: remove the object when its one-shot animation completes.
local spine = require("plugin.spine")
local phase = arg[1] or "completed"
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj
obj = spine.create(data, function(e)
  print("listener:", e.phase or e.name, e.animation, "type(e.target)=" .. type(e.target))
  if (e.phase or e.name) == phase and obj then
    print("  -> calling obj:removeSelf() inside the listener")
    local o = obj; obj = nil
    o:removeSelf()
    print("  <- removeSelf returned")
  end
end)
obj:setAnimation(1, "idle-turn", false)   -- 0.27 s one-shot
for i = 1, 40 do
  if not obj then break end
  local o = obj
  o:updateState(16)
end
print("survived")
