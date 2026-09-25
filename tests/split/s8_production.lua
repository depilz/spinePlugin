-- s8: realistic production patterns with the oracle after every frame (real removal timing).
--  P1 avatar (mix-and-match skins): split at the start of a sequence, animation changes/queues, skin change while split,
--     re-split with other slots, injection into a split slot, reassemble at the end; 3 sequences per avatar.
--  P2 chibi-stickers (10 atlas pages, draw-order animations, 9 skins): split during draw-order animations + skin swaps.
--  P3 raptor roar/jump (draw-order keys) with a "weapon" injected into a split slot, re-split every 15 frames.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock = C.mock; io.stdout:setvbuf("no")
local total = { frames = 0, bad = 0, raised = 0 }

local function runFrames(ctx, n, label)
  for f = 1, n do
    local ok, err = pcall(C.frame, ctx.obj)
    mock.endFrame()
    total.frames = total.frames + 1; ctx.frames = ctx.frames + 1
    if not ok then
      total.raised = total.raised + 1; ctx.raised = ctx.raised + 1
      ctx.msg = ctx.msg or (label .. ": " .. tostring(err):gsub("^.-ENGINE", "ENGINE"):sub(1, 150))
    else
      local e = C.check(ctx.obj, ctx.sg, ctx.injs, label .. " f" .. f)
      if #e > 0 then total.bad = total.bad + 1; ctx.bad = ctx.bad + 1; ctx.msg = ctx.msg or e[1] end
    end
  end
end
local function report(name, ctx)
  print(("%-3s %5d frames, oracle-bad %d, draw raised %d%s"):format(name, ctx.frames, ctx.bad, ctx.raised, ctx.msg and (" | first: " .. ctx.msg:sub(1, 200)) or ""))
end
local function new(name, scale)
  local scene = display.newGroup()
  local back, mid, front = display.newGroup(), display.newGroup(), display.newGroup()
  scene:insert(back); scene:insert(mid); scene:insert(front)
  local obj = C.spine.create(C.data(name, scale or 0.5)); mid:insert(obj)
  obj.x, obj.y = 160, 400
  local prop = display.newRect(0, 0, 50, 50); mid:insert(prop)   -- something the split parts must be layered above
  return { scene = scene, front = front, obj = obj, frames = 0, bad = 0, raised = 0, injs = {} }
end
local function splitInto(ctx, slots)
  local ok, g = pcall(ctx.obj.split, ctx.obj, slots)
  if not ok then ctx.raised = ctx.raised + 1; ctx.msg = ctx.msg or ("split raised: " .. tostring(g)); return end
  ctx.sg = g
  ctx.front:insert(g)                        -- layer the split parts in front of the prop
  g.x, g.y = ctx.obj.x, ctx.obj.y            -- same content transform as the skeleton
end
local function reassemble(ctx)
  local ok, err = pcall(ctx.obj.reassemble, ctx.obj)
  if not ok then ctx.raised = ctx.raised + 1; ctx.msg = ctx.msg or ("reassemble raised: " .. tostring(err)) end
  ctx.sg = nil
end

-- P1
do
  local ctx = new("mix-and-match")
  local obj = ctx.obj
  local avatars = { "full-skins/girl", "full-skins/boy", "full-skins/girl-blue-cape", "full-skins/girl-spring-dress" }
  local weapon = display.newRect(0, 0, 8, 30)
  for a = 1, #avatars do
    obj:setSkin(avatars[a])
    obj:setAnimation(1, "idle", true)
    runFrames(ctx, 5, "P1 idle " .. a)
    for seqn = 1, 3 do
      splitInto(ctx, { "arm-front", "hand-front", "sleeve-front", "sleeve-inner-front" })
      if seqn == 2 and not ctx.injected then obj:inject(weapon, "hand-front"); ctx.injs = { { obj = weapon, slot = "hand-front" } }; ctx.injected = true end
      obj:setAnimation(1, "dance", false)
      obj:addAnimation(1, "walk", true, 0)
      runFrames(ctx, 40, ("P1 %s seq%d dance/walk"):format(avatars[a], seqn))
      obj:setSkin(avatars[(a % #avatars) + 1])  -- skin change while split
      runFrames(ctx, 15, "P1 skin change while split")
      obj:setSkin(avatars[a])
      splitInto(ctx, { "leg-front", "boot-ribbon-front", "hand-front", "arm-front" })  -- re-split, other slots
      obj:setAnimation(1, "aware", false); obj:addAnimation(1, "idle", true, 0)
      runFrames(ctx, 30, "P1 re-split aware/idle")
      reassemble(ctx)
      runFrames(ctx, 10, "P1 reassembled")
    end
  end
  report("P1", ctx)
end

-- P2
do
  local ctx = new("chibi-stickers", 0.3)
  local obj = ctx.obj
  local anims = { "emotes/angry", "emotes/dramatic-stare", "emotes/excited", "movement/trot-front", "movement/trot-left", "emotes/fawning" }
  local skins = { "erikari", "harri", "luke", "mario", "misaki", "nate" }
  for i, anim in ipairs(anims) do
    obj:setSkin(skins[i])
    obj:setAnimation(1, anim, true)
    splitInto(ctx, { "arm-r", "glove-r", "sword", "shield", "head-base", "hair-front" })
    runFrames(ctx, 40, "P2 " .. anim)
    obj:setSkin(skins[(i % #skins) + 1])
    runFrames(ctx, 20, "P2 skin swap while split")
    if i % 2 == 0 then reassemble(ctx); runFrames(ctx, 10, "P2 reassembled") end
  end
  if ctx.sg then reassemble(ctx); runFrames(ctx, 10, "P2 final reassemble") end
  report("P2", ctx)
end

-- P3
do
  local ctx = new("raptor")
  local obj = ctx.obj
  local weapon = display.newRect(0, 0, 8, 30)
  obj:inject(weapon, "front-hand")
  ctx.injs = { { obj = weapon, slot = "front-hand" } }
  local sets = { { "front-hand", "front-arm", "gun" }, { "raptor-horn", "front-hand", "neck" }, { "front-thigh", "lower-leg", "front-hand" } }
  for i = 1, 12 do
    obj:setAnimation(1, (i % 2 == 0) and "roar" or "jump", false)
    splitInto(ctx, sets[(i % #sets) + 1])
    runFrames(ctx, 15, "P3 " .. i)
  end
  reassemble(ctx); runFrames(ctx, 10, "P3 reassembled")
  report("P3", ctx)
end
print(("TOTAL %d frames, oracle-bad %d, raised %d"):format(total.frames, total.bad, total.raised))
C.expect(total.bad == 0 and total.raised == 0, "production split patterns disagree with the oracle or raise")
C.done()
