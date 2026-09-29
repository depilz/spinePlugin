-- The next-frame dispose hook: a finalized skeleton raises from RestoreTable on and is freed by the next frame's
-- Runtime "enterFrame" hook, which skips a user-dispatched finalize, re-arms after an app cleared its Runtime
-- listeners and, with no Runtime at all, is replaced by an immediate dispose inside finalize. The all-refs modes check
-- that each dispose path releases the create() listener, the group "spine" listener and onComplete together.
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
-- a spine object whose create() listener, group "spine" listener and onComplete closure are held only through it
local function newAllRefs()
  local obj = newTracked("create")
  local groupListener, onComplete = function() end, function() end
  weak.group, weak.onComplete = groupListener, onComplete
  obj:addEventListener("spine", groupListener)
  obj:setAnimation(1, "run", true).onComplete = onComplete
  obj:updateState(16); obj:draw()
  return obj
end
local function allReleased()
  S.gcfull()
  print("still referenced: create", weak.create, "group", weak.group, "onComplete", weak.onComplete)
  return weak.create == nil and weak.group == nil and weak.onComplete == nil
end

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
elseif mode == "split-busy" then
  -- with no Runtime, finalized during draw (busy): the outermost guard's dispose takes the skeleton's meshes out of
  -- the caller's split group and leaves the group with the caller
  local obj = newTracked("obj")
  local splitGroup = obj:split({ "head", "eye", "mouth" })
  local layer = display.newGroup(); layer:insert(splitGroup)
  local armed, fired = false, false
  obj:inject(display.newGroup(), "torso", function()
    if armed and not fired then fired = true; obj:dispatchEvent({ name = "finalize", target = obj }) end
  end)
  obj:updateState(16); obj:draw()
  local before = #S.children(splitGroup)
  armed = true
  local runtime = Runtime
  Runtime = nil
  local ok, err = pcall(obj.draw, obj)
  Runtime = runtime
  print("draw with a disposing injection listener ->", ok, err, "listener fired", fired,
    "split group children before", before, "after", #S.children(splitGroup))
  assert(ok and fired and before > 0, "draw did not survive a dispose from its injection listener")
  assert(#S.children(splitGroup) == 0, "the skeleton's meshes stayed in the caller's split group")
  assert(splitGroup.parent == layer, "the caller's split group was moved or removed")
  assert(disposed("obj"), "draw's call guard did not free the skeleton")
elseif mode == "all-refs-busy" then
  -- with no Runtime, removed and finalized during draw (busy): the outermost guard's dispose releases all three refs
  local obj = newAllRefs()
  local splitGroup = obj:split({ "head", "eye", "mouth" })
  display.newGroup():insert(splitGroup)
  local armed, fired, heldInDraw = false, false, false
  obj:inject(display.newGroup(), "torso", function()
    if armed and not fired then
      fired = true
      obj:removeSelf(); S.endFrame()
      heldInDraw = not disposed("create")
    end
  end)
  obj:updateState(16); obj:draw()
  armed = true
  local runtime = Runtime
  Runtime = nil
  local ok, err = pcall(obj.draw, obj)
  Runtime = runtime
  print("draw with a removing injection listener ->", ok, err, "listener fired", fired, "held in draw", heldInDraw)
  assert(ok and fired, "draw did not survive a finalize from its injection listener")
  assert(heldInDraw, "finalize freed the skeleton inside draw")
  assert(#S.children(splitGroup) == 0, "the skeleton's meshes stayed in the caller's split group")
  obj = nil
  assert(allReleased(), "draw's call guard did not release every Lua ref")
elseif mode == "all-refs-no-runtime" then
  -- with no Runtime, finalize outside any call (busy == 0) disposes at once and releases all three refs
  local obj = newAllRefs()
  local runtime = Runtime
  Runtime = nil
  obj:removeSelf(); obj = nil
  S.endFrame()
  Runtime = runtime
  assert(allReleased(), "finalize without Runtime did not release every Lua ref")
elseif mode == "all-refs-hook" then
  -- with a Runtime, the next-frame hook's dispose releases all three refs
  local obj = newAllRefs()
  obj:removeSelf(); obj = nil
  S.endFrame()
  assert(not disposed("create"), "the skeleton was freed before the next frame")
  S.frame()
  assert(allReleased(), "the next-frame hook did not release every Lua ref")
elseif mode == "split-coroutine" or mode == "split-coroutine-no-runtime" then
  -- created in a coroutine that is collected before its parent is removed: the dispose that takes the meshes out of
  -- the caller's split group (the next-frame hook, or finalize with no Runtime) must not run Lua on the dead thread
  local parent, layer = display.newGroup(), display.newGroup()
  local obj
  local co = coroutine.create(function() obj = newTracked("obj"); parent:insert(obj) end)
  assert(coroutine.resume(co)); co = nil
  local splitGroup = obj:split({ "head", "eye", "mouth" })
  layer:insert(splitGroup)
  obj:updateState(16); obj:draw()
  local before = #S.children(splitGroup)
  S.gcfull()                                    -- the finished coroutine and its lua_State are collected
  local runtime = Runtime
  if mode == "split-coroutine-no-runtime" then Runtime = nil end
  display.remove(parent); obj = nil
  S.endFrame()                                  -- finalize: frees at once with no Runtime, else arms the hook
  Runtime = runtime
  S.frame()
  print("split group children before", before, "after", #S.children(splitGroup))
  assert(before > 0 and #S.children(splitGroup) == 0, "the skeleton's meshes stayed in the caller's split group")
  assert(splitGroup.parent == layer, "the caller's split group was moved or removed")
  assert(disposed("obj"), "the skeleton was not freed")
end
print("survived")
