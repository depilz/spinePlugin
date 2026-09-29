-- A property write on a removed skeleton (docs/lifecycle.rst "Writing properties"). "removed": after removeSelf the
-- write goes to the display group (skeleton_newindex's removed branch): no raise, no check, the animation state keeps
-- its own value, and the skeleton reads the key as nil (the stub keeps group fields in __props). "parent": a parent
-- removal leaves the skeleton live until the end-of-frame finalize, so the write still reaches the animation state.
-- "finalized": after finalize the object is a plain table and the write is a plain field.
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1]
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj = spine.create(data)
local entry = obj:setAnimation(1, "walk", true)
local updateState = obj.updateState

if mode == "removed" then
  S.raises("physicsTimeScale must be a finite number >= 0", function() obj.physicsTimeScale = -1 end) -- live: checked
  obj:removeSelf()
  assert(pcall(function() obj.timeScale = 2 end), "a timeScale write on a removed skeleton raised")
  assert(pcall(function() obj.physicsTimeScale = -1 end), "a removed skeleton still checks physicsTimeScale")
  print("after removeSelf: obj.timeScale =", obj.timeScale, "group field =", rawget(obj, "__props").timeScale)
  assert(obj.timeScale == nil, "a removed skeleton reads the written key")
  assert(rawget(obj, "__props").timeScale == 2, "the write did not reach the display group")
  local before = entry.trackTime
  updateState(obj, 100)                         -- a stored method still advances the state in the removal frame
  print("trackTime advanced by", entry.trackTime - before)
  assert(math.abs(entry.trackTime - before - 100) < 0.01, "the write changed the animation state's timeScale")
elseif mode == "parent" then
  local parent = display.newGroup()
  parent:insert(obj)
  display.remove(parent)
  obj.timeScale = 2
  print("after the parent removal: obj.timeScale =", obj.timeScale)
  assert(obj.timeScale == 2, "the write before finalize did not reach the animation state")
elseif mode == "finalized" then
  obj:removeSelf()
  S.frame()                                     -- finalize strips the metatable; the frame's hook frees the skeleton
  assert(getmetatable(obj) == nil, "the end-of-frame finalize left a metatable")
  assert(pcall(function() obj.timeScale = 2 end), "a timeScale write on a finalized skeleton raised")
  print("after finalize: rawget(obj, 'timeScale') =", rawget(obj, "timeScale"))
  assert(rawget(obj, "timeScale") == 2, "the write on a finalized skeleton is not a plain field")
end
S.frame()
S.gcfull()
