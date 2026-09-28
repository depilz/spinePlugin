-- The next-frame dispose hook: a finalized skeleton raises from RestoreTable on and is freed by the next frame's
-- Runtime "enterFrame" hook, which skips a user-dispatched finalize, re-arms after an app cleared its Runtime
-- listeners and, with no Runtime at all, is replaced by an immediate dispose inside finalize.
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1]
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local weak = setmetatable({}, { __mode = "v" })

-- a spine object whose animation listener is held only by the skeleton: weak[name] goes nil once it is disposed
local function newTracked(name)
  local listener = function() end
  weak[name] = listener
  local obj = spine.create(data, listener)
  obj:setAnimation(1, "walk", true); obj:updateState(16); obj:draw()
  return obj
end
local function disposed(name) S.gcfull(); return weak[name] == nil end

if mode == "window" then
  local parent = display.newGroup()
  local obj = newTracked("obj")
  parent:insert(obj)
  local bone, setAnimation, removeSelf = obj.bones[1], obj.setAnimation, obj.removeSelf
  local finalizeRead, heldBone, freshBone
  obj:addEventListener("finalize", function(e)
    finalizeRead = e.target:getCurrentAnimation(1)
    heldBone, freshBone = bone.x, e.target.bones[1].x
  end)
  display.remove(parent)
  S.endFrame()                                  -- finalize, then RestoreTable; the next frame has not begun
  print("user finalize listener read", finalizeRead, heldBone, freshBone)
  assert(finalizeRead == "walk", "a user finalize listener could not use the object")
  assert(type(heldBone) == "number" and type(freshBone) == "number", "a user finalize listener saw dead wrappers")
  assert(getmetatable(obj) == nil, "RestoreTable left a metatable")
  S.raises("Bone belongs to a removed skeleton", function() return bone.x end)
  S.raises("Skeleton belongs to a removed skeleton", setAnimation, obj, 1, "run", true)
  S.raises("Skeleton belongs to a removed skeleton", removeSelf, obj)
  assert(not disposed("obj"), "the skeleton was freed before the next frame")
  S.frame()
  assert(disposed("obj"), "the next-frame hook did not free the skeleton")
  S.raises("Skeleton belongs to a removed skeleton", setAnimation, obj, 1, "run", true)
elseif mode == "user-finalize" then
  local obj = newTracked("obj")
  local bone = obj.bones[1]
  obj:dispatchEvent({ name = "finalize", target = obj })
  local entry = obj:setAnimation(1, "run", true)
  print("same frame after a user-dispatched finalize: bone.x", bone.x, "entry.isValid", entry.isValid)
  assert(type(bone.x) == "number" and entry.isValid and entry.animation ~= nil,
    "a user-dispatched finalize killed the wrappers")
  S.frame()
  print("after a user-dispatched finalize and a frame: bone.x", bone.x)
  assert(type(bone.x) == "number" and obj.removeSelf ~= nil, "the hook did not leave a live object alone")
  obj:updateState(16); obj:draw()
  obj:removeSelf(); S.frame()
  assert(disposed("obj"), "a later removal did not free the skeleton")
elseif mode == "rearm" then
  local a = newTracked("a")
  a:removeSelf(); S.endFrame()                  -- queued, hook armed
  rawset(Runtime, "_functionListeners", nil)    -- the app clears every Runtime listener
  S.frame()
  assert(not disposed("a"), "the hook ran although the app removed it")
  local b = newTracked("b")
  b:removeSelf(); S.frame()                     -- the next finalize re-arms the hook
  assert(disposed("a") and disposed("b"), "the hook was not re-armed")
elseif mode == "no-runtime" then
  local obj = newTracked("obj")
  local getCurrentAnimation, lateCall = obj.getCurrentAnimation, nil
  obj:addEventListener("finalize", function(e) lateCall = { pcall(getCurrentAnimation, e.target, 1) } end)
  local runtime = Runtime
  Runtime = nil
  obj:removeSelf(); S.endFrame()                -- finalize must not raise; with no hook it frees at once
  Runtime = runtime
  print("a later finalize listener's cached call on the disposed object ->", lateCall[1], lateCall[2])
  assert(not lateCall[1] and tostring(lateCall[2]):find("Skeleton belongs to a removed skeleton", 1, true),
    "a cached method on the disposed object did not raise")
  assert(disposed("obj"), "without Runtime the skeleton was not freed")
elseif mode == "reassemble" then
  -- with no Runtime, an injection listener's finalize frees at once: reassemble's re-draw must stop, not reuse it
  local obj = newTracked("obj")
  local splitGroup = obj:split({ "head", "eye", "mouth" })
  display.newGroup():insert(splitGroup)
  local fired = false
  obj:inject(display.newGroup(), "head", function()
    if Runtime == nil and not fired then fired = true; obj:dispatchEvent({ name = "finalize", target = obj }) end
  end)
  local runtime = Runtime
  Runtime = nil
  local ok, err = pcall(obj.reassemble, obj)
  Runtime = runtime
  print("reassemble with a disposing injection listener ->", ok, err, "listener fired", fired)
  assert(ok and fired, "reassemble did not survive a dispose from its injection listener")
  assert(splitGroup.parent == nil, "reassemble left the split group on stage")
  S.endFrame()
  assert(S.isRemoved(splitGroup), "the split group was not finalized")
  assert(disposed("obj"), "reassemble's call guard did not free the skeleton")
elseif mode == "reassemble-remove" then
  -- with a Runtime, an injection listener removing its own skeleton during reassemble: the split group still goes
  local obj = newTracked("obj")
  local splitGroup = obj:split({ "head", "eye", "mouth" })
  display.newGroup():insert(splitGroup)
  local fired = false
  obj:inject(display.newGroup(), "head", function()
    if not fired then fired = true; obj:removeSelf() end
  end)
  local ok, err = pcall(obj.reassemble, obj)
  print("reassemble with a removing injection listener ->", ok, err, "listener fired", fired,
    "split group parent", splitGroup.parent)
  assert(ok and fired, "reassemble did not survive a removeSelf from its injection listener")
  assert(splitGroup.parent == nil, "reassemble left the split group on stage")
  S.frame()
  assert(S.isRemoved(splitGroup), "the split group was not finalized")
  assert(disposed("obj"), "the next-frame hook did not free the skeleton")
end
print("survived")
