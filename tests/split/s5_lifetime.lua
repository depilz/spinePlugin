-- s5: split-group lifetime. Real Solar2D removal timing: removed objects are finalized at mock.endFrame().
-- Each case prints: errors raised, meshes left on screen outside the skeleton, oracle state. arg[1] selects the case
-- (L1..L8); no arg = all.
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local mock = C.mock; io.stdout:setvbuf("no")
local which = arg[1]

local function meshesUnder(g)
  local n = 0
  if not g or mock.isFinalized(g) then return 0 end
  for _, c in ipairs(mock.children(g)) do
    if mock.kind(c) == "mesh" then n = n + 1 elseif mock.kind(c) == "group" then n = n + meshesUnder(c) end
  end
  return n
end
local function onScreenMeshes() return meshesUnder(mock.stage) end
local live = {}
local function cleanup()
  for _, t in ipairs(live) do
    if t.obj.removeSelf then pcall(t.obj.removeSelf, t.obj) end
    display.remove(t.sg); display.remove(t.scene); if t.hud then display.remove(t.hud) end
  end
  live = {}
  mock.endFrame()
end
local function setup()
  cleanup()
  local scene = display.newGroup()
  local layer = display.newGroup(); scene:insert(layer)
  local obj = C.spine.create(C.data("raptor", 0.5)); scene:insert(obj)
  obj:setAnimation(1, "walk", true)
  C.frame(obj); mock.endFrame()
  local sg = obj:split({ "raptor-body", "raptor-horn", "front-thigh", "gun" }); layer:insert(sg)
  for f = 1, 3 do C.frame(obj); mock.endFrame() end
  live[#live + 1] = { obj = obj, sg = sg, scene = scene }
  return scene, layer, obj, sg
end
local function frames(obj, sg, n, label)
  local raised, bad, msg = 0, 0, nil
  for f = 1, n do
    local ok, err = pcall(C.frame, obj)
    mock.endFrame()
    if not ok then raised = raised + 1; msg = msg or tostring(err):gsub("^.-ENGINE", "ENGINE"):sub(1, 150)
    else
      local e = C.check(obj, sg, nil, label)
      if #e > 0 then bad = bad + 1; msg = msg or e[1] end
    end
  end
  return ("%d frames: draw raised %d, oracle-bad %d%s"):format(n, raised, bad, msg and (" | " .. msg) or "")
end
local function pc(f, ...) local ok, err = pcall(f, ...); return ok and "ok" or ("raised: " .. tostring(err):gsub("^.-ENGINE", "ENGINE"):sub(1, 120)) end
-- a frames() result with every draw ok and matching the oracle
local function clean(s) return s:match("draw raised 0, oracle%-bad 0$") ~= nil end

-- L1 removeSelf while split
if not which or which == "L1" then
  local scene, layer, obj, sg = setup()
  local before = onScreenMeshes()
  local r = pc(obj.removeSelf, obj); mock.endFrame()
  local after = onScreenMeshes()
  print(("L1 removeSelf while split: %s; meshes on screen before=%d after=%d; split group finalized=%s"):format(r, before, after, tostring(mock.isFinalized(sg))))
  C.expect(r == "ok" and after == 0, "L1: removeSelf while split leaves the split meshes on screen (tests-examples-14)")
  local r2 = pc(display.remove, sg); mock.endFrame()
  print(("   caller then display.remove(splitGroup) (next frame): %s"):format(r2))
  C.expect(r2 == "ok", "L1: display.remove(splitGroup) after removeSelf")
end

-- L1b removeSelf while split, then the caller removes the group with a METHOD call in a later frame (compatibility)
if not which or which == "L1b" then
  local scene, layer, obj, sg = setup()
  obj:removeSelf(); mock.endFrame()
  local r = pc(function() sg:removeSelf() end); mock.endFrame()
  print(("L1b removeSelf while split, next frame splitGroup:removeSelf(): %s; meshes on screen=%d"):format(r, onScreenMeshes()))
  C.expect(r == "ok" and onScreenMeshes() == 0, "L1b: splitGroup:removeSelf() after the skeleton's removeSelf")
end

-- L2 caller removes the split group, skeleton keeps drawing
if not which or which == "L2" then
  local scene, layer, obj, sg = setup()
  display.remove(sg)
  local same = pc(C.frame, obj)
  mock.endFrame()
  local later = frames(obj, nil, 10, "L2")
  print(("L2 display.remove(splitGroup): draw in the same frame: %s; later %s"):format(same, later))
  C.expect(same == "ok" and clean(later), "L2: draws fail after the caller removed the split group (lifecycle-15)")
  print(("   meshes on screen=%d (all under the skeleton: %s)"):format(onScreenMeshes(), tostring(meshesUnder(obj) == onScreenMeshes())))
end

-- L3 caller removes the split group, then reassemble() (same frame / next frame)
if not which or which == "L3" then
  for _, when in ipairs({ "same frame", "next frame" }) do
    local scene, layer, obj, sg = setup()
    display.remove(sg)
    if when == "next frame" then pcall(C.frame, obj); mock.endFrame() end
    local r = pc(obj.reassemble, obj); mock.endFrame()
    local later = frames(obj, nil, 10, "L3")
    print(("L3 display.remove(splitGroup), reassemble() %s: %s; then %s"):format(when, r, later))
    C.expect(r == "ok" and clean(later), "L3 " .. when .. ": reassemble() after the caller removed the split group (lifecycle-15)")
  end
end

-- L4 caller removes the split group, then split() again
if not which or which == "L4" then
  local scene, layer, obj, sg = setup()
  display.remove(sg); pcall(C.frame, obj); mock.endFrame()
  local ok, sg2 = pcall(obj.split, obj, { "raptor-body", "gun" })
  local newGroup = ok and sg2 ~= sg and not mock.isFinalized(sg2)
  if ok and sg2 and not mock.isFinalized(sg2) then scene:insert(sg2) end
  local later = frames(obj, ok and sg2 or nil, 10, "L4")
  print(("L4 split() after the caller removed the old group: %s, returns a live new group=%s; then %s"):format(ok and "ok" or ("raised: " .. tostring(sg2)), tostring(newGroup), later))
  C.expect(newGroup and clean(later), "L4: split() after the caller removed the split group returns the dead group (lifecycle-15)")
end

-- L5 scene removal (skeleton and split group both inside the removed scene)
if not which or which == "L5" then
  local scene, layer, obj, sg = setup()
  display.remove(scene); mock.endFrame()
  local alive = obj.parent ~= nil
  local r = alive and pc(C.frame, obj) or "skipped (obj.parent == nil)"
  print(("L5 display.remove(scene) with both inside: loop guard obj.parent -> %s; draw: %s; meshes on screen=%d"):format(tostring(obj.parent), r, onScreenMeshes()))
  C.expect((not alive or r == "ok") and onScreenMeshes() == 0, "L5: draw or meshes left on screen after scene removal")
end

-- L6 the split group's parent layer is removed, the skeleton stays
if not which or which == "L6" then
  local scene, layer, obj, sg = setup()
  display.remove(layer)
  local same = pc(C.frame, obj); mock.endFrame()
  local later = frames(obj, nil, 10, "L6")
  print(("L6 display.remove(layer holding the split group): same-frame draw %s; later %s"):format(same, later))
  C.expect(same == "ok" and clean(later), "L6: draws fail after the split group's layer was removed (lifecycle-15)")
end

-- L7 the skeleton's parent is removed, the split group lives on in another layer (e.g. a HUD)
if not which or which == "L7" then
  local scene, layer, obj, sg = setup()
  local hud = display.newGroup(); hud:insert(sg); live[#live].hud = hud
  display.remove(scene); mock.endFrame(); mock.endFrame()   -- 2 frames: a deferred removal may run one frame later
  print(("L7 skeleton removed with its parent, split group in another layer: split group live=%s, meshes left on screen=%d"):format(
    tostring(not mock.isFinalized(sg) and mock.onscreen(sg)), meshesUnder(hud)))
  C.expect(meshesUnder(hud) == 0, "L7: the split group outlives its removed skeleton with meshes on screen (lifecycle-15)")
end

-- L7b skeleton and split group in the same removed scene, split layer BEFORE the skeleton (collected after it)
if not which or which == "L7b" then
  local scene, layer, obj, sg = setup()     -- scene = [layer(sg), obj]: Solar2D finalizes children last-to-first
  local ok, err = pcall(function() display.remove(scene); mock.endFrame(); mock.endFrame() end)
  print(("L7b scene removed, split layer below the skeleton: %s; split group finalized=%s; meshes on screen=%d"):format(
    ok and "ok" or ("raised: " .. tostring(err):gsub("^.-ENGINE", "ENGINE"):sub(1, 120)), tostring(mock.isFinalized(sg)), onScreenMeshes()))
  C.expect(ok and onScreenMeshes() == 0, "L7b: scene removal with the split layer below the skeleton")
end

-- L8 removeSelf after the caller removed the split group (same frame / next frame)
if not which or which == "L8" then
  for _, when in ipairs({ "same frame", "next frame" }) do
    local scene, layer, obj, sg = setup()
    display.remove(sg)
    if when == "next frame" then pcall(C.frame, obj); mock.endFrame() end
    local r = pc(obj.removeSelf, obj); mock.endFrame()
    print(("L8 display.remove(splitGroup) then removeSelf() %s: %s; meshes on screen=%d"):format(when, r, onScreenMeshes()))
    C.expect(r == "ok" and onScreenMeshes() == 0, "L8 " .. when .. ": removeSelf() after the caller removed the split group")
  end
end
cleanup()
print(("meshes on screen after cleanup: %d"):format(onScreenMeshes()))
C.done()
