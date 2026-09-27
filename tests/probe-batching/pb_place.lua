-- probe-batching combined render oracle: injection placement (independent per-slot reference) + mesh list realization
-- after EVERY draw, over every drawn slot of every example skeleton, several animations and time points.
-- Skeletons: the Corona/spines examples. arg[1] = "split" (or env PB_SPLIT=1): the skeleton is split into a fixed pseudo-random half of its slots for the per-slot cases.
-- Cases per slot: inject into a drawn slot, draw (V1); if the slot shows a REGION: hide it with attachment alpha 0
-- (the 0-index dummy command path, spine/SkeletonRenderer.cpp:199-214), draw x3 (H1-H3), restore, draw (Hback); draw (V2).
-- Case M (per animation): 3 injections at random drawn slots, one of them hidden, 30 animated frames (+ split/re-split/
-- reassemble in split mode).
-- Error classes (per checked frame): P = injected object misplaced/wrong group vs the unbatched reference;
-- R = mesh children differ from the tree's own batched command list (order/count/vertices/texture/blend/color);
-- Q = paint only (blend/color/texture differ, e.g. render-6); G = vertex total per group differs from the reference;
-- F = plugin references a finalized mesh; X = draw raised. A frame can count in several classes.
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local mock, fx = C.mock, C.fx
io.stdout:setvbuf("no")
local SPLIT = arg[1] == "split" or os.getenv("PB_SPLIT") == "1"
local MAXA = tonumber(os.getenv("PB_MAXA") or "4")
local ONLY = os.getenv("PB_ONLY")

local skels = { { "alien" }, { "celestial-circus" }, { "chibi-stickers", "erikari" }, { "cloud-pot" }, { "coin" }, { "dragon" },
  { "goblins", "goblin" }, { "hero", "weapon/sword" }, { "mix-and-match", "full-skins/girl" }, { "owl" }, { "powerup" },
  { "raptor" }, { "sack" }, { "snowglobe" }, { "speedy" }, { "spineboy" }, { "stretchyman" }, { "tank" }, { "vine" }, { "windmill" } }

local T = { checks = 0, P = 0, R = 0, Q = 0, G = 0, F = 0, X = 0, placements = 0, hidden = 0 }
local byCase = {}
local examples = {}
local function classify(errs)
  local c = {}
  for _, e in ipairs(errs) do
    if e:find("injected object") then c.P = true
    elseif e:find("draws %d+ vertices, reference") then c.G = true
    elseif e:find("finalized") then c.F = true
    elseif e:find(": blend ") or e:find(": color ") or e:find(": texture ") then c.Q = true
    else c.R = true end
  end
  return c
end
-- PB_SIG=<file>: also write one display-list signature line per checked frame ("<key> | <main> | <split>[ #BAD]"),
-- comparable across builds with sigcmp.py (keys are the running check number + case + where)
local SIGF = os.getenv("PB_SIG") and assert(io.open(os.getenv("PB_SIG"), "w"))
local CUR = { obj = nil, sg = nil, injs = nil }
local nsig = 0
local function sig(g)
  if not g then return "-" end
  local t = {}
  for _, c in ipairs(mock.children(g)) do
    local k = mock.kind(c)
    if k == "mesh" then local pt = mock.paint(c); t[#t + 1] = ("m%d/%s/%s/%.3f,%.3f,%.3f,%.3f"):format(mock.vertexCount(c) or -1, pt.blendMode, tostring(pt.spec and pt.spec.filename), pt.color[1], pt.color[2], pt.color[3], pt.color[4])
    else local lbl = "o"; for i, inj in ipairs(CUR.injs or {}) do if inj.obj == c then lbl = "inj" .. i end end; t[#t + 1] = lbl end
  end
  return table.concat(t, ",")
end
local function tally(case, errs, raised, where)
  if SIGF then nsig = nsig + 1; SIGF:write(("%d:%s:%s | %s | %s%s\n"):format(nsig, case, where, raised and "RAISED" or sig(CUR.obj), raised and "-" or sig(CUR.sg), (raised or #errs > 0) and " #BAD" or "")) end
  local b = byCase[case]; if not b then b = { checks = 0, P = 0, R = 0, Q = 0, G = 0, F = 0, X = 0 }; byCase[case] = b end
  b.checks = b.checks + 1; T.checks = T.checks + 1
  if raised then b.X = b.X + 1; T.X = T.X + 1; if #examples < 12 then examples[#examples + 1] = case .. " " .. where .. " RAISED " .. tostring(raised):sub(1, 160) end; return end
  local c = classify(errs)
  for k in pairs(c) do b[k] = b[k] + 1; T[k] = T[k] + 1 end
  if (c.P or c.R or c.G or c.F) and #examples < 12 then local m = errs[1]; for _, e in ipairs(errs) do if not (e:find(": blend ") or e:find(": color ") or e:find(": texture ")) then m = e; break end end; examples[#examples + 1] = case .. " " .. where .. ": " .. m:sub(1, 200) end
end

local function draw(obj) local ok, err = pcall(obj.draw, obj); mock.endFrame(); if not ok then return err end end
local function frame(obj) local ok, err = pcall(C.frame, obj); mock.endFrame(); if not ok then return err end end

local perSkel = {}
for si, sk in ipairs(skels) do
  if not ONLY or ONLY == sk[1] then
  local okd, data = pcall(C.data, sk[1], 0.5)
  if not okd then print(("%-17s LOAD FAILED (%s)"):format(sk[1], tostring(data):sub(-80))) else
  local before = { checks = T.checks, P = T.P, R = T.R, Q = T.Q, G = T.G, F = T.F, X = T.X, placements = T.placements, hidden = T.hidden }
  local scene = display.newGroup()
  local obj = C.spine.create(data); scene:insert(obj)
  if sk[2] then obj:setSkin(sk[2]) end
  local slotNames = obj:getSlotNames()
  local anims = obj:getAnimations()
  table.sort(anims)
  local pick = {}
  local step = math.max(1, math.floor(#anims / MAXA))
  for i = 1, #anims, step do if #pick < MAXA then pick[#pick + 1] = anims[i] end end
  if sk[1] == "spineboy" then local has = false; for _, a in ipairs(pick) do if a == "portal" then has = true end end; if not has then pick[#pick + 1] = "portal" end end
  math.randomseed(si * 7919)
  local sg
  local splitSet = {}
  if SPLIT then for _, s in ipairs(slotNames) do if math.random() < 0.5 then splitSet[#splitSet + 1] = s end end end
  for ai, anim in ipairs(pick) do
    obj:setAnimation(1, anim, true)
    for f = 1, 2 do frame(obj) end
    if SPLIT and not sg then sg = obj:split(splitSet); scene:insert(sg); draw(obj) end
    -- per-slot cases at two time points
    for tp = 1, 2 do
      for f = 1, (tp == 1 and 6 or 23) do frame(obj) end
      local ref = fx.reference(obj)
      local drawn = {}
      for _, r in ipairs(ref) do if r.n >= 3 then drawn[#drawn + 1] = r.name end end
      for _, sname in ipairs(drawn) do
        local where = ("%s/%s t%d %s"):format(sk[1], anim, tp, sname)
        local marker = display.newRect(0, 0, 1, 1)
        repeat -- Lua 5.1: repeat/break instead of goto
        if not pcall(obj.inject, obj, marker, sname) then marker:removeSelf(); break end
        local injs = { { obj = marker, slot = sname } }
        CUR.obj, CUR.sg, CUR.injs = obj, sg, injs
        local case = (SPLIT and "S" or "") .. "V"
        T.placements = T.placements + 1
        do local r = draw(obj); tally(case .. "1", r and {} or C.check(obj, sg, injs, "v"), r, where) end
        if fx.attachmentKind(obj, sname) == "region" then
          local keep = fx.attachmentAlpha(obj, sname)
          if keep and keep > 0 then
            T.hidden = T.hidden + 1
            fx.setAttachmentAlpha(obj, sname, 0)
            local hcase = (SPLIT and "S" or "") .. "H"
            for d = 1, 3 do local r = draw(obj); tally(hcase .. d, r and {} or C.check(obj, sg, injs, "h"), r, where) end
            fx.setAttachmentAlpha(obj, sname, keep)
            local r = draw(obj); tally(hcase .. "back", r and {} or C.check(obj, sg, injs, "hb"), r, where)
          end
        end
        do local r = draw(obj); tally(case .. "2", r and {} or C.check(obj, sg, injs, "v"), r, where) end
        obj:eject(marker); marker:removeSelf(); draw(obj)
        until true
      end
    end
    -- case M: 3 injections, one hidden, animated
    do
      local ref = fx.reference(obj)
      local drawn = {}
      for _, r in ipairs(ref) do if r.n >= 3 then drawn[#drawn + 1] = r.name end end
      if #drawn >= 1 then
        local injs, hiddenSlot, keep = {}, nil, nil
        local picks = {}
        for k = 1, 3 do picks[#picks + 1] = drawn[math.random(#drawn)] end
        local used = {}
        for _, s in ipairs(picks) do
          if not used[s] then
            used[s] = true
            local m = display.newRect(0, 0, 1, 1)
            if pcall(obj.inject, obj, m, s) then injs[#injs + 1] = { obj = m, slot = s } else m:removeSelf() end
            if not hiddenSlot and fx.attachmentKind(obj, s) == "region" then
              local a = fx.attachmentAlpha(obj, s); if a and a > 0 then hiddenSlot, keep = s, a end
            end
          end
        end
        if hiddenSlot then fx.setAttachmentAlpha(obj, hiddenSlot, 0) end
        local mcase = (SPLIT and "S" or "") .. "M"
        CUR.obj, CUR.sg, CUR.injs = obj, sg, injs
        for f = 1, 30 do
          if SPLIT and f == 11 then local t = {}; for _, s in ipairs(slotNames) do if math.random() < 0.5 then t[#t + 1] = s end end; obj:split(t) end
          if SPLIT and f == 21 then if hiddenSlot then fx.setAttachmentAlpha(obj, hiddenSlot, keep); hiddenSlot = nil end; obj:reassemble(); sg = nil end
          local r = frame(obj)
          CUR.sg = sg
          tally(mcase, r and {} or C.check(obj, sg, injs, "m"), r, ("%s/%s f%d"):format(sk[1], anim, f))
        end
        if hiddenSlot then fx.setAttachmentAlpha(obj, hiddenSlot, keep) end
        for _, i in ipairs(injs) do if not mock.isFinalized(i.obj) then obj:eject(i.obj); i.obj:removeSelf() else T.lost = (T.lost or 0) + 1 end end
        draw(obj)
        if SPLIT and not sg then sg = obj:split(splitSet); scene:insert(sg); draw(obj) end
      end
    end
  end
  pcall(function() obj:removeSelf() end); display.remove(scene); mock.endFrame()
  local d = {}
  for _, k in ipairs({ "checks", "P", "R", "Q", "G", "F", "X", "placements", "hidden" }) do d[k] = T[k] - (before[k] or 0) end
  print(("%-17s anims=%d placements=%4d hidden=%4d checks=%5d | P=%d R=%d Q=%d G=%d F=%d X=%d"):format(sk[1], #pick, d.placements, d.hidden, d.checks, d.P, d.R, d.Q, d.G, d.F, d.X))
  end
  end
end
local keys = {}; for k in pairs(byCase) do keys[#keys + 1] = k end; table.sort(keys)
for _, k in ipairs(keys) do local b = byCase[k]; print(("  case %-6s checks=%6d P=%d R=%d Q=%d G=%d F=%d X=%d"):format(k, b.checks, b.P, b.R, b.Q, b.G, b.F, b.X)) end
for _, e in ipairs(examples) do print("  e.g. " .. e) end
print(("TOTAL split=%s placements=%d hidden=%d checks=%d P=%d R=%d Q=%d G=%d F=%d X=%d lost=%d"):format(tostring(SPLIT), T.placements, T.hidden, T.checks, T.P, T.R, T.Q, T.G, T.F, T.X, T.lost or 0))
C.expect(T.P == 0, T.P .. " checks with an injected object misplaced vs the unbatched reference (render-1)")
C.expect(T.R + T.G + T.F == 0, ("%d/%d/%d checks with mesh list (R), vertex total (G) or finalized-mesh (F) errors"):format(T.R, T.G, T.F))
C.expect(T.Q == 0, T.Q .. " checks with paint errors (blend/color/texture)")
C.expect(T.X == 0, T.X .. " draws raised (render-2)")
C.done()
