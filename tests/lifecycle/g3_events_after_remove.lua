-- gap-6 g3: no listener event reaches Lua after the object removed itself inside a callback.
--   ended:       clearTrack(1) queues end + dispose; remove on 'ended'
--   interrupted: setAnimation(1,"run") on a playing walk queues interrupt(walk) + start(run); remove on 'interrupted'
local spine = require("plugin.spine")
local S = __stub
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local mode = arg[1]
local obj, removed, after = nil, false, {}
obj = spine.create(data, function(e)
  local tag = (e.phase or e.name) .. ":" .. tostring(e.animation)
  if removed then after[#after + 1] = tag end
  if not removed and e.phase == mode then
    removed = true
    obj:removeSelf()
    print("removed inside '" .. tag .. "'")
  end
end)
obj:setAnimation(1, "walk", true)
obj:updateState(16)
if mode == "ended" then obj:clearTrack(1) else obj:setAnimation(1, "run", true) end
print("events delivered after removal in the same drain:", #after, table.concat(after, " "))
assert(removed, "the listener never saw '" .. mode .. "'")
assert(#after == 0, "events delivered after removal")
S.frame(); S.gcfull()
