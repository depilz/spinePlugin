-- s10: an app's split call order replayed on public assets, oracle and stray meshes checked after every frame:
--  1 play, then a timer splits all slots but a "behind" set into a sibling caller layer; the caller moves the split
--    group every frame to follow the skeleton and leaves it split for a later consumer
--  2 the later consumer reassemble()s from a timer (no split of its own)
--  3 play, a timer splits with another behind set, a plain Lua completion callback in the frame loop reassemble()s
--  4 reassemble() when not split, and twice in a row: no-op
--  5 removeSelf() while split, no reassemble first: the skeleton's meshes leave the caller's group, the group stays
-- Splits come from timers or the frame loop, never from an animation listener; no inject/eject. mix-and-match uses
-- s9's part sets; spineboy's split set includes its clipping slot.
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local mock = C.mock; io.stdout:setvbuf("no")

local cases = {
  { name = "mix-and-match", skin = "full-skins/girl", anims = { "dance", "walk" },
    behind = { "arm-back", "hand-back", "sleeve-inner-back", "cape-back", "cape-up-back" },
    behind2 = { "leg-back", "boot-ribbon-back", "hair-back", "bag-strap-back", "backpack" } },
  { name = "spineboy", anims = { "portal", "walk" },
    behind = { "portal-bg", "portal-shade", "portal-streaks2", "portal-streaks1" },
    behind2 = { "rear-upper-arm", "rear-bracer", "gun", "rear-foot", "rear-thigh", "rear-shin" } },
}

local total = { frames = 0, bad = 0, raised = 0, stray = 0 }
local firstMsg
local function note(msg) firstMsg = firstMsg or msg end

local function meshesUnder(g)
  local n = 0
  for _, c in ipairs(mock.children(g)) do if mock.kind(c) == "mesh" then n = n + 1 end end
  return n
end

-- one app frame: the caller's follow step, update + draw, the checks, then the end of frame. The mock runs timers
-- in endFrame, after the draw: a timer's split or reassemble is what the next frame draws, so check before it.
local function frame(ctx, label)
  ctx.obj.x = ctx.obj.x + 1
  if ctx.sg then ctx.sg.x, ctx.sg.y = ctx.obj.x, ctx.obj.y end
  local ok, err = pcall(C.frame, ctx.obj)
  total.frames = total.frames + 1
  if not ok then total.raised = total.raised + 1; note(label .. ": draw raised " .. tostring(err))
  else
    local e = C.check(ctx.obj, ctx.sg, nil, label)
    if #e > 0 then total.bad = total.bad + 1; note(e[1]) end
    local stray = C.strayMeshes(ctx.obj, ctx.sg)
    if stray > 0 then total.stray = total.stray + 1; note(("%s: %d stray meshes"):format(label, stray)) end
  end
  mock.endFrame()
end
local function frames(ctx, n, label, onFrame)
  for f = 1, n do
    if onFrame then onFrame(f) end
    frame(ctx, label .. " f" .. f)
  end
end

local function allBut(obj, behind)
  local skip, set = {}, {}
  for _, s in ipairs(behind) do skip[s] = true end
  for _, s in ipairs(C.slotNames(obj)) do if not skip[s] then set[#set + 1] = s end end
  return set
end
local function delayedSplit(ctx, behind)
  timer.performWithDelay(300, function()
    ctx.sg = ctx.obj:split(allBut(ctx.obj, behind))
    ctx.front:insert(ctx.sg)
  end)
end
local function reassemble(ctx, label)
  local ok, err = pcall(ctx.obj.reassemble, ctx.obj)
  if not ok then total.raised = total.raised + 1; note(label .. ": reassemble raised " .. tostring(err)) end
  ctx.sg = nil
end

for _, case in ipairs(cases) do
  local scene = display.newGroup()
  local back, front = display.newGroup(), display.newGroup()   -- the skeleton's layer and a sibling caller layer
  scene:insert(back); scene:insert(front)
  local obj = C.spine.create(C.data(case.name, 0.5)); back:insert(obj)
  obj.x, obj.y = 160, 400
  if case.skin then obj:setSkin(case.skin) end
  local ctx = { obj = obj, front = front }
  local L = case.name

  -- 1
  obj:setAnimation(1, case.anims[1], true)
  frames(ctx, 5, L .. " 1 play")
  delayedSplit(ctx, case.behind)
  frames(ctx, 40, L .. " 1 split, following")
  C.expect(ctx.sg ~= nil, L .. " 1: the timer did not split")

  -- 2
  timer.performWithDelay(300, function() reassemble(ctx, L .. " 2") end)
  frames(ctx, 15, L .. " 2 delayed reassemble")

  -- 3
  obj:setAnimation(1, case.anims[2], false)
  frames(ctx, 3, L .. " 3 play")
  delayedSplit(ctx, case.behind2)
  local function onComplete() reassemble(ctx, L .. " 3 completion") end
  frames(ctx, 40, L .. " 3 split", function(f) if f == 30 then onComplete() end end)

  -- 4
  local ok1 = pcall(obj.reassemble, obj)
  frames(ctx, 3, L .. " 4 reassemble unsplit")
  delayedSplit(ctx, case.behind)
  frames(ctx, 5, L .. " 4 split")
  local ok2 = pcall(obj.reassemble, obj)
  local ok3 = pcall(obj.reassemble, obj)
  ctx.sg = nil
  frames(ctx, 5, L .. " 4 reassemble twice")
  C.expect(ok1 and ok2 and ok3, L .. " 4: reassemble() when not split, or twice, raised")

  -- 5
  obj:setAnimation(1, case.anims[1], true)
  delayedSplit(ctx, case.behind2)
  frames(ctx, 10, L .. " 5 split")
  local sg = ctx.sg
  local before = meshesUnder(sg)
  local ok = pcall(obj.removeSelf, obj)
  local now = meshesUnder(sg)   -- before the end of frame: the mock has no Runtime, so its finalize frees at once
  mock.endFrame(); mock.endFrame()
  local left = meshesUnder(sg)
  local kept = not mock.isFinalized(sg) and mock.onscreen(sg)
  local stray = C.strayMeshes(nil, nil)
  print(("%s 5 removeSelf while split: %s; split group meshes before=%d, after removeSelf=%d, after 2 frames=%d; group kept by the caller=%s; meshes on screen=%d"):format(
    L, ok and "ok" or "raised", before, now, left, tostring(kept), stray))
  C.expect(ok and before > 0 and now == 0 and left == 0 and kept and stray == 0,
    L .. " 5: removeSelf while split must take the skeleton's meshes out of the caller's group and leave the group")
  display.remove(sg); display.remove(scene); mock.endFrame()
end

print(("TOTAL %d frames, oracle-bad %d, draw raised %d, frames with stray meshes %d"):format(total.frames, total.bad, total.raised, total.stray))
if firstMsg then print("  first: " .. firstMsg:sub(1, 220)) end
C.expect(total.bad == 0 and total.raised == 0 and total.stray == 0, "the app's split sequences disagree with the oracle, raise or leave stray meshes")
C.done()
