-- v3: split with 2 injections per skeleton, the oracle after every frame (C4, rewritten from the recorded verify-split-3
-- definition: 3,000 frames; it fails where an injected object is placed before a newly created mesh, which the group-only
-- S2 form misses). 10 skeletons x 3 rounds x 2 phases x 50 frames. Each round is a new object: inject 2 objects into 2
-- drawn slots (1 into the only slot of the 4.2 sequence fixture) and split a seeded random half of the slots plus both
-- injected slots before the first draw (p1), then re-split another random half plus the first injected slot (p2), then
-- remove the object. Also prints the group:insert calls.
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local mock, fx = C.mock, C.fx
io.stdout:setvbuf("no")
local ROUNDS, FRAMES = 3, 50
local skels = { { "alien" }, C.SEQUENCE, { "goblins", "goblin" }, { "chibi-stickers", "erikari" }, { "mix-and-match", "full-skins/girl" },
  { "owl" }, { "raptor" }, { "speedy" }, { "stretchyman" }, { "tank" } }

local T = { frames = 0, bad = 0 }
local first
mock.resetStats()
for si, sk in ipairs(skels) do
  for r = 1, ROUNDS do
    math.randomseed(si * 100 + r)
    local scene = display.newGroup()
    local obj = C.spine.create(C.data(sk[1], 0.5)); scene:insert(obj)
    if sk[2] then obj:setSkin(sk[2]) end
    obj:setAnimation(1, obj:getAnimations()[1], true)
    obj:updateState(0)
    local drawn, injs = {}, {}
    for _, e in ipairs(fx.reference(obj)) do drawn[#drawn + 1] = e.name end
    for k = 1, math.min(2, #drawn) do
      local slot = table.remove(drawn, math.random(#drawn))
      local o = display.newRect(0, 0, 10, 10)
      obj:inject(o, slot)
      injs[k] = { obj = o, slot = slot }
    end
    local slots = C.slotNames(obj)
    local sg
    for p = 1, 2 do
      local set = { injs[1].slot, p == 1 and injs[2] and injs[2].slot or nil }
      for _, n in ipairs(slots) do if math.random() < 0.5 then set[#set + 1] = n end end
      local ok, g = pcall(obj.split, obj, set)
      if ok then sg = g; scene:insert(sg) end
      for f = 1, FRAMES do
        local label = ("%s r%d p%d f%d"):format(sk[1], r, p, f)
        local okf, err = pcall(C.frame, obj); mock.endFrame()
        T.frames = T.frames + 1
        local errs = not ok and { "split raised: " .. tostring(g) } or not okf and { "draw raised: " .. tostring(err) } or C.check(obj, sg, injs, "x")
        if #errs > 0 then
          T.bad = T.bad + 1
          first = first or (label .. ": " .. table.concat(errs, " ; "))
        end
      end
    end
    pcall(function() obj:removeSelf() end)
    display.remove(scene); mock.endFrame()
  end
end
if first then print("  first: " .. first:sub(1, 600)) end
print(("frames %d, oracle-bad or raised %d, group:insert calls %d"):format(T.frames, T.bad, mock.stats.insert or 0))
C.expect(T.bad == 0, "split frames with injections disagree with the oracle or raise (render-7; on the 4.2 as-is batcher also render-1)")
C.done()
