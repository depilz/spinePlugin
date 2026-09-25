-- s1: random slot sets (as Corona/tests/Splits.lua), oracle after every frame.
-- phases per run: split(A) 20 frames -> split(B) 20 frames -> reassemble 20 frames -> split(C) 20 frames -> reassemble 5 frames
-- Real Solar2D removal timing (removed objects are finalized at the end of the frame).
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock = C.mock; io.stdout:setvbuf("no")
local RUNS = tonumber(os.getenv("RUNS") or "30")
local SKIP = arg[1] == "skip-portal"  -- as-is builds crash (render-2) on spineboy/portal when split
local skels = { { "raptor", nil }, { "spineboy", nil }, { "tank", nil }, { "celestial-circus", nil }, { "mix-and-match", "full-skins/girl" } }
local phaseNames = { "split A", "re-split B", "reassembled", "split C", "reassembled 2" }
local grand = { frames = 0, bad = 0, raised = 0 }
for _, sk in ipairs(skels) do
  local name, skin = sk[1], sk[2]
  local badBy, frames, raised, strays, firstMsg = { 0, 0, 0, 0, 0 }, 0, 0, 0, nil
  local stickyRuns = 0
  for run = 1, RUNS do
    math.randomseed(run * 7919)
    local scene = display.newGroup()
    local obj = C.spine.create(C.data(name, 0.5))
    scene:insert(obj)
    if skin then obj:setSkin(skin) end
    local anims = {}
    for _, a in ipairs(obj:getAnimations()) do if not (SKIP and a == "portal") then anims[#anims + 1] = a end end
    obj:setAnimation(1, anims[math.random(#anims)], true)
    C.frame(obj); mock.endFrame()
    local slots = C.slotNames(obj)
    local function randomSlots()
      local t = {}
      for _, s in ipairs(slots) do if math.random() < 0.5 then t[#t + 1] = s end end
      return t
    end
    local sg
    local lastBadPhase
    local ok, err = pcall(function()
      for phase = 1, 5 do
        if phase == 1 or phase == 2 or phase == 4 then sg = obj:split(randomSlots()); scene:insert(sg) end
        if phase == 3 or phase == 5 then obj:reassemble() end
        local nf = phase == 5 and 5 or 20
        for f = 1, nf do
          phaseNow = phase
          C.frame(obj); mock.endFrame(); frames = frames + 1
          local e = C.check(obj, sg, nil, ("%s run %d %s f%d"):format(name, run, phaseNames[phase], f))
          if #e > 0 then
            badBy[phase] = badBy[phase] + 1
            firstMsg = firstMsg or e[1]
            if f == nf then lastBadPhase = phase end
          end
          strays = math.max(strays, C.strayMeshes(obj, sg))
        end
      end
    end)
    if lastBadPhase then stickyRuns = stickyRuns + 1 end
    if not ok then
      raised = raised + 1
      if raised <= 2 then print(("   run %d raised in phase '%s': %s"):format(run, phaseNames[phaseNow] or "?", tostring(err):gsub("^[^:]*spines/", ""):sub(1, 200))) end
    end
    pcall(function() obj:removeSelf() end)
    display.remove(scene); mock.endFrame()
  end
  local bad = 0; for i = 1, 5 do bad = bad + badBy[i] end
  grand.frames = grand.frames + frames; grand.bad = grand.bad + bad; grand.raised = grand.raised + raised
  print(("%-17s frames=%4d bad=%4d [A %d | reSplit %d | reasm %d | C %d | reasm2 %d] still-wrong-at-phase-end runs=%d raised=%d maxStray=%d"):format(
    name, frames, bad, badBy[1], badBy[2], badBy[3], badBy[4], badBy[5], stickyRuns, raised, strays))
  if firstMsg then print("   first: " .. firstMsg:sub(1, 220)) end
end
print(("TOTAL frames=%d bad=%d raised=%d%s"):format(grand.frames, grand.bad, grand.raised, SKIP and "  [portal skipped]" or ""))
C.expect(grand.bad == 0 and grand.raised == 0, "split/re-split/reassemble frames disagree with the oracle or draw() raised (render-7)")
C.done()
