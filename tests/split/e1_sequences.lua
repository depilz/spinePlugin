-- e1: split sequences with the oracle after every frame (C4, rewritten from the recorded verify-split-1 definition: 37
-- skeletons on 4.2, 38 on 4.3, x 12 sequences). Skeletons: the examples and the line's sequence rig, each loaded from
-- every export it has (.skel and .json; the 4.2 sequence fixture is JSON only). One object per skeleton; each sequence
-- plays one animation, splits a seeded random half of the slots, draws 40 frames (split phase), reassembles and draws
-- 18 frames (after reassemble). No injections. A skeleton whose draw() raised starts no further sequences; one that
-- does not load fails the test.
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local mock = C.mock; io.stdout:setvbuf("no")
local SEQS, SPLIT_FRAMES, AFTER_FRAMES = 12, 40, 18
local examples = { { "alien" }, { "celestial-circus" }, { "chibi-stickers", "erikari" }, { "cloud-pot" }, { "coin" }, C.SEQUENCE,
  { "goblins", "goblin" }, { "mix-and-match", "full-skins/girl" }, { "owl" }, { "powerup" },
  { "raptor" }, { "sack" }, { "snowglobe" }, { "speedy" }, { "spineboy" }, { "stretchyman" }, { "tank" }, { "vine" }, { "windmill" } }

-- load(name, ext): <name>/<file>.<ext> with its atlas, <file> the last path component of name (see C.data)
local function load(name, ext)
  local base = ("%s/%s"):format(name, name:match("[^/]+$"))
  local atlas = C.spine.loadAtlas(base .. ".atlas")
  return C.spine.loadSkeletonData(base .. "." .. ext, atlas, 0.5)
end

local T = { skeletons = 0, started = 0, badSeqs = 0, badSplit = 0, badAfter = 0, frames = 0, wrong = 0, raised = 0 }
local unloaded, first = {}, nil
for ei, e in ipairs(examples) do
  for fi, ext in ipairs(e.exts or { "skel", "json" }) do
    local okd, data = pcall(load, e[1], ext)
    if not okd then unloaded[#unloaded + 1] = e[1] .. "." .. ext else
      T.skeletons = T.skeletons + 1
      local scene = display.newGroup()
      local obj = C.spine.create(data); scene:insert(obj)
      if e[2] then obj:setSkin(e[2]) end
      local anims = obj:getAnimations(); table.sort(anims)
      local slots = C.slotNames(obj)
      local badSeqs, msg = T.badSeqs, nil
      local ok, err = pcall(function()
        for s = 1, SEQS do
          math.randomseed(ei * 1000 + fi * 100 + s)
          T.started = T.started + 1
          obj:setAnimation(1, anims[(s - 1) % #anims + 1], true)
          C.frame(obj); mock.endFrame()
          local set = {}
          for _, n in ipairs(slots) do if math.random() < 0.5 then set[#set + 1] = n end end
          local sg = obj:split(set); scene:insert(sg)
          local seqBad = false
          for phase = 1, 2 do
            if phase == 2 then obj:reassemble(); sg = nil end
            local phaseBad = false
            for f = 1, phase == 1 and SPLIT_FRAMES or AFTER_FRAMES do
              C.frame(obj); mock.endFrame(); T.frames = T.frames + 1
              local errs = C.check(obj, sg, nil, ("%s.%s seq %d %s f%d"):format(e[1], ext, s, phase == 1 and "split" or "after", f))
              if #errs > 0 then
                T.wrong = T.wrong + 1; msg = msg or errs[1]
                if not phaseBad then phaseBad = true; if phase == 1 then T.badSplit = T.badSplit + 1 else T.badAfter = T.badAfter + 1 end end
                if not seqBad then seqBad = true; T.badSeqs = T.badSeqs + 1 end
              end
            end
          end
        end
      end)
      if not ok then T.raised = T.raised + 1; msg = msg or ("draw raised: " .. tostring(err)) end
      if msg then -- one line per skeleton with a wrong frame or a raise: its first error
        print(("  %s.%s: %d bad sequences%s | %s"):format(e[1], ext, T.badSeqs - badSeqs, ok and "" or ", draw raised", msg:sub(1, 200)))
        first = first or msg
      end
      pcall(function() obj:removeSelf() end)
      display.remove(scene); mock.endFrame()
    end
  end
end
print(("%d skeletons x %d sequences: %d sequences started, %d with a wrong frame (split phase %d, after reassemble %d); wrong frames %d/%d; skeletons whose draw() raised: %d"):format(
  T.skeletons, SEQS, T.started, T.badSeqs, T.badSplit, T.badAfter, T.wrong, T.frames, T.raised))
if #unloaded > 0 then print("  not loaded: " .. table.concat(unloaded, ", ")) end
if first then print("  first: " .. first:sub(1, 220)) end
C.expect(#unloaded == 0, "skeletons not loaded: " .. table.concat(unloaded, ", "))
C.expect(T.started == T.skeletons * SEQS and T.badSeqs == 0 and T.raised == 0, "split sequences disagree with the oracle or draw() raised (render-7)")
C.done()
