-- probe-batching: oracle after every frame with NO injections (plain content; clipping yields empty commands on rule ii / 4.3),
-- every animation x 120 frames, Corona/spines examples. Split mode with arg[1] = "split" (or env PB_SPLIT=1).
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock, fx = C.mock, C.fx
io.stdout:setvbuf("no")
local SPLIT = arg[1] == "split" or os.getenv("PB_SPLIT") == "1"
local list = {}
for _, s in ipairs({ { "alien" }, { "celestial-circus" }, { "chibi-stickers", "erikari" }, { "cloud-pot" }, { "coin" }, { "dragon" },
  { "goblins", "goblin" }, { "hero", "weapon/sword" }, { "mix-and-match", "full-skins/girl" }, { "owl" }, { "powerup" },
  { "raptor" }, { "sack" }, { "snowglobe" }, { "speedy" }, { "spineboy" }, { "stretchyman" }, { "tank" }, { "vine" }, { "windmill" } }) do
  list[#list + 1] = { label = s[1], load = function() return C.data(s[1], 0.5) end, skin = s[2] }
end
local T = { frames = 0, bad = 0, R = 0, G = 0, X = 0 }
for si, e in ipairs(list) do
  local okd, data = pcall(e.load)
  if okd then
    local scene = display.newGroup()
    local obj = C.spine.create(data); scene:insert(obj)
    if e.skin then obj:setSkin(e.skin) end
    local sg
    if SPLIT then math.randomseed(si * 131); local t = {}; for _, s in ipairs(obj:getSlotNames()) do if math.random() < 0.5 then t[#t + 1] = s end end; sg = obj:split(t); scene:insert(sg) end
    local anims = obj:getAnimations(); table.sort(anims)
    local step = #anims > 24 and math.floor(#anims / 24) or 1
    local frames, bad, first = 0, 0, nil
    for ai = 1, #anims, step do
      obj:setAnimation(1, anims[ai], true)
      for f = 1, 120 do
        local ok, err = pcall(C.frame, obj); mock.endFrame(); frames = frames + 1
        local errs = ok and C.check(obj, sg, nil, anims[ai] .. " f" .. f) or { "RAISED " .. tostring(err) }
        if #errs > 0 then bad = bad + 1; first = first or errs[1]; if not ok then T.X = T.X + 1 end end
      end
    end
    T.frames = T.frames + frames; T.bad = T.bad + bad
    if bad > 0 then print(("%-24s frames=%5d bad=%d first: %s"):format(e.label, frames, bad, tostring(first):sub(1, 150))) end
    pcall(function() obj:removeSelf() end); display.remove(scene); mock.endFrame()
  end
end
print(("TOTAL no-injection frames=%d bad=%d raised=%d split=%s"):format(T.frames, T.bad, T.X, tostring(SPLIT)))
C.expect(T.bad == 0, T.bad .. " frames differ from the oracle")
C.done()
