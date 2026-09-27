-- probe-batching: Solar2D mesh counts per skeleton (no injections, unsplit), averaged over every animation x 60 frames.
-- Also: new meshes created per frame (mesh churn) and group:insert calls per frame, from the mock's counters.
-- Skeletons: the Corona/spines examples. env PB_FRAMES: frames per animation (default 60).
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local mock, fx = C.mock, C.fx
io.stdout:setvbuf("no")
local FR = tonumber(os.getenv("PB_FRAMES") or "60")
local list = {}
for _, s in ipairs({ { "alien" }, { "celestial-circus" }, { "chibi-stickers", "erikari" }, { "cloud-pot" }, { "coin" }, { "dragon" },
  { "goblins", "goblin" }, { "hero", "weapon/sword" }, { "mix-and-match", "full-skins/girl" }, { "owl" }, { "powerup" },
  { "raptor" }, { "sack" }, { "snowglobe" }, { "speedy" }, { "spineboy" }, { "stretchyman" }, { "tank" }, { "vine" }, { "windmill" } }) do
  list[#list + 1] = { label = s[1], load = function() return C.data(s[1], 0.5) end, skin = s[2] }
end
local grand = { meshes = 0, frames = 0 }
-- PB_SIG=<file>: one display-list signature line per frame (sigcmp.py format, no oracle flag) for cross-build parity checks
local SIGF = os.getenv("PB_SIG") and assert(io.open(os.getenv("PB_SIG"), "w"))
local nsig = 0
local function sig(g)
  local t = {}
  for _, c in ipairs(mock.children(g)) do
    if mock.kind(c) == "mesh" then local pt = mock.paint(c); t[#t + 1] = ("m%d/%s/%s/%.3f,%.3f,%.3f,%.3f"):format(mock.vertexCount(c) or -1, pt.blendMode, tostring(pt.spec and pt.spec.filename), pt.color[1], pt.color[2], pt.color[3], pt.color[4]) else t[#t + 1] = "o" end
  end
  return table.concat(t, ",")
end
for _, e in ipairs(list) do
  local okd, data = pcall(e.load)
  if not okd then print(("%-28s LOAD FAILED"):format(e.label)) else
    local obj = C.spine.create(data)
    if e.skin then obj:setSkin(e.skin) end
    local anims = obj:getAnimations(); table.sort(anims)
    local step = 1
    if #anims > 24 then step = math.floor(#anims / 24) end
    local frames, meshSum, meshMax, newSum, insSum, emptyCmd = 0, 0, 0, 0, 0, 0
    for ai = 1, #anims, step do
      obj:setAnimation(1, anims[ai], true)
      for f = 1, FR do
        local n0, i0 = mock.stats.newMesh or 0, mock.stats.insert or 0
        C.frame(obj); mock.endFrame()
        if SIGF then nsig = nsig + 1; SIGF:write(("%d:%s:%s:%d | %s | -\n"):format(nsig, e.label, anims[ai], f, sig(obj))) end
        local n = 0
        for _, ch in ipairs(mock.children(obj)) do if mock.kind(ch) == "mesh" then n = n + 1 end end
        frames = frames + 1; meshSum = meshSum + n; if n > meshMax then meshMax = n end
        newSum = newSum + ((mock.stats.newMesh or 0) - n0); insSum = insSum + ((mock.stats.insert or 0) - i0)
        if f == FR then for _, c in ipairs(fx.expected(obj)) do if c.numIndices == 0 then emptyCmd = emptyCmd + 1 end end end
      end
    end
    grand.meshes = grand.meshes + meshSum / frames; grand.frames = grand.frames + 1
    print(("%-28s anims=%3d frames=%5d meshes/frame avg=%6.2f max=%3d  newMesh/frame=%.3f  insert/frame=%.2f  emptyCmds(last frame of each anim)=%d"):format(
      e.label, math.ceil(#anims / step), frames, meshSum / frames, meshMax, newSum / frames, insSum / frames, emptyCmd))
    obj:removeSelf(); mock.endFrame()
  end
end
print(("TOTAL sum of per-skeleton avg meshes/frame = %.1f over %d skeletons"):format(grand.meshes, grand.frames))
