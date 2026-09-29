-- s4: injections while split. arg[1] selects the case (a, b2, c..g); no arg = a (with b2), c, e, f.
-- "a" checks cases a/b, "b2" repeats them and checks only the reassembled frames.
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local mock = C.mock; io.stdout:setvbuf("no")
local which = arg[1]

local function setup(anim)
  local scene = display.newGroup()
  local obj = C.spine.create(C.data("raptor", 0.5)); scene:insert(obj)
  obj:setAnimation(1, anim or "walk", true)
  C.frame(obj); mock.endFrame()
  return scene, obj
end
local function listenerLog()
  local log = { calls = 0, frames = {} }
  log.fn = function(e) log.calls = log.calls + 1; local t = log.cur; t[#t + 1] = e.isVisible and "T" or "F" end
  log.begin = function() log.cur = {}; log.frames[#log.frames + 1] = log.cur end
  return log
end
local function run(label, obj, sg, injs, n, logs, between)
  local bad, first = 0, nil
  for f = 1, n do
    for _, l in ipairs(logs or {}) do l.begin() end
    if between then between(f) end
    local ok, err = pcall(C.frame, obj)
    mock.endFrame()
    if not ok then return ("%s: draw raised at frame %d: %s"):format(label, f, tostring(err):gsub("^.-ENGINE", "ENGINE"):sub(1, 160)) end
    local e = C.check(obj, sg, injs, label .. " f" .. f)
    if #e > 0 then bad = bad + 1; first = first or e[1] end
  end
  return ("%s: %d frames, oracle-bad=%d%s"):format(label, n, bad, first and (" first: " .. first) or "")
end
-- prints a run() result and checks it: every frame drawn and matching the oracle
local function expectClean(r, finding)
  print(r)
  C.expect(r:match(", oracle%-bad=0$") ~= nil, r .. (finding and (" (" .. finding .. ")") or ""))
end
local function seq(log) -- summarize listener sequences, e.g. "FT x20"
  local counts, order = {}, {}
  for _, fr in ipairs(log.frames) do local k = table.concat(fr); if not counts[k] then counts[k] = 0; order[#order + 1] = k end; counts[k] = counts[k] + 1 end
  local t = {}; for _, k in ipairs(order) do t[#t + 1] = ("{%s} x%d"):format(k == "" and "-" or k, counts[k]) end
  return table.concat(t, ", ")
end

-- (a) inject into a split slot and a non-split slot; (b) re-split swaps which one is split
if not which or which == "a" or which == "b2" then
  local scene, obj = setup()
  local A = display.newRect(0, 0, 10, 10); local B = display.newRect(0, 0, 10, 10)
  local la, lb = listenerLog(), listenerLog()
  obj:inject(A, "raptor-horn", la.fn); obj:inject(B, "front-thigh", lb.fn)
  local injs = { { obj = A, slot = "raptor-horn" }, { obj = B, slot = "front-thigh" } }
  local sg = obj:split({ "raptor-horn", "raptor-body", "raptor-front-leg" }); scene:insert(sg)
  local checkAB = which ~= "b2"
  local function listeners(label)
    local a, b = seq(la), seq(lb)
    print(("    listener per frame  A%s: %s | B%s: %s"):format(label and "(split slot)" or "", a, label and "(skeleton slot)" or "", b))
    if checkAB then C.expect(a == "{T} x20" and b == "{T} x20", "injection listener called more than once per frame (render-8)") end
  end
  local r = run("(a) split with injections in both groups", obj, sg, injs, 20, { la, lb })
  if checkAB then expectClean(r) else print(r) end
  listeners(true)
  la.frames, lb.frames = {}, {}
  obj:split({ "front-thigh", "raptor-body" })
  r = run("(b) re-split moves injection slots between groups", obj, sg, injs, 20, { la, lb })
  if checkAB then expectClean(r) else print(r) end
  listeners(false)
  obj:reassemble()
  r = run("(b2) reassembled", obj, nil, injs, 10)
  if which ~= "a" then expectClean(r, "adjacent injection slots merged by the inverted batching rule, render-1") else print(r) end
end

-- (c) reassemble while the injected object's split slot is hidden (no attachment)
if not which or which == "c" then
  local scene, obj = setup()
  local A = display.newRect(0, 0, 10, 10)
  obj:inject(A, "raptor-horn")
  local sg = obj:split({ "raptor-horn", "raptor-body" }); scene:insert(sg)
  for f = 1, 3 do C.frame(obj); mock.endFrame() end
  local inSplit = mock.parentOf(A) == sg
  obj:setAttachment("raptor-horn", nil)
  C.frame(obj); mock.endFrame()
  obj:reassemble(); mock.endFrame()
  print(("(c) injected object in split slot (in split group: %s), slot hidden, reassemble(): object finalized=%s, parent is skeleton=%s"):format(
    tostring(inSplit), tostring(mock.isFinalized(A)), tostring(mock.parentOf(A) == obj)))
  C.expect(not mock.isFinalized(A) and mock.parentOf(A) == obj, "reassemble() destroyed the injected object of a hidden split slot (split-8)")
  obj:setSlotsToSetupPose()   -- show the slot again (4.3 branch setAttachment(slot, name) crashes without a skin)
  local ok = pcall(C.frame, obj); mock.endFrame()
  local shown = not mock.isFinalized(A) and mock.onscreen(A)
  print(("    slot shown again: draw ok=%s, object on screen=%s"):format(tostring(ok), tostring(shown)))
  C.expect(ok and shown, "injected object not back on screen once its slot is shown (split-8)")
end

-- (g) hide and show again the slots of injections with listeners, one in the split group and one in the skeleton
if which == "g" then
  local scene, obj = setup()
  local A = display.newRect(0, 0, 10, 10); local B = display.newRect(0, 0, 10, 10)
  local la, lb = listenerLog(), listenerLog()
  obj:inject(A, "raptor-horn", la.fn); obj:inject(B, "front-thigh", lb.fn)
  local injs = { { obj = A, slot = "raptor-horn" }, { obj = B, slot = "front-thigh" } }
  local sg = obj:split({ "raptor-horn", "raptor-body" }); scene:insert(sg)
  local function phase(label, n, want, between)
    la.frames, lb.frames = {}, {}
    if between then between() end
    expectClean(run("(g) " .. label, obj, sg, injs, n, { la, lb }))
    local a, b = seq(la), seq(lb)
    print(("    listener per frame  A(split slot): %s | B(skeleton slot): %s"):format(a, b))
    C.expect(a == want and b == want, ("(g) %s: listeners %s | %s, expected %s (render-8)"):format(label, a, b, want))
  end
  phase("visible", 5, "{T} x5")
  phase("hide both slots", 1, "{F} x1", function() obj:setAttachment("raptor-horn", nil); obj:setAttachment("front-thigh", nil) end)
  phase("hidden", 5, "{-} x5")
  phase("re-shown", 5, "{T} x5", function() obj:setSlotsToSetupPose() end)   -- 4.3 setAttachment(slot, name) crashes without a skin
end

-- (d) render-2 via injection: inject into a split slot whose region attachment has alpha 0 and is drawn FIRST in the split pass
if which == "d" then
  local scene, obj = setup()
  local A = display.newRect(0, 0, 10, 10)
  obj:inject(A, "back-hand")                       -- first slot in raptor's draw order
  print("    back-hand attachment kind: " .. tostring(C.fx.attachmentKind(obj, "back-hand")))
  C.fx.setAttachmentAlpha(obj, "back-hand", 0)      -- 0-alpha placeholder => 0-index dummy command
  local sg = obj:split({ "back-hand", "raptor-body" }); scene:insert(sg)
  expectClean(run("(d) split pass starts with an injection dummy (alpha-0 region)", obj, sg, { { obj = A, slot = "back-hand" } }, 20), "render-2")
end

-- (e) alpha-0 injection slot in the MIDDLE of a batchable run (batching + dummy commands), split and unsplit
if not which or which == "e" then
  for _, mode in ipairs({ "unsplit", "split" }) do
    local scene, obj = setup()
    local A = display.newRect(0, 0, 10, 10)
    obj:inject(A, "back-arm")                        -- region between back-hand and back-bracer (same page/color/blend)
    assert(C.fx.setAttachmentAlpha(obj, "back-arm", 0))
    local sg
    if mode == "split" then sg = obj:split({ "back-hand", "back-arm", "back-bracer", "back-knee" }); scene:insert(sg) end
    expectClean(run("(e) " .. mode .. ": alpha-0 injection slot between batchable slots", obj, sg, { { obj = A, slot = "back-arm" } }, 20))
  end
end

-- (f) inject / eject / changeInjectionSlot while split
if not which or which == "f" then
  local scene, obj = setup()
  local sg = obj:split({ "raptor-horn", "raptor-body" }); scene:insert(sg)
  C.frame(obj); mock.endFrame()
  local A = display.newRect(0, 0, 10, 10)
  obj:inject(A, "raptor-horn")
  local injs = { { obj = A, slot = "raptor-horn" } }
  expectClean(run("(f1) inject while split", obj, sg, injs, 5))
  obj:changeInjectionSlot(A, "front-thigh"); injs[1].slot = "front-thigh"
  expectClean(run("(f2) changeInjectionSlot to a skeleton slot", obj, sg, injs, 5))
  obj:changeInjectionSlot(A, "raptor-body"); injs[1].slot = "raptor-body"
  expectClean(run("(f3) changeInjectionSlot back to a split slot", obj, sg, injs, 5))
  obj:eject(A)
  expectClean(run("(f4) eject while split", obj, sg, {}, 5))
  print(("    ejected object parent is stage: %s"):format(tostring(mock.parentOf(A) == mock.stage)))
  C.expect(mock.parentOf(A) == mock.stage, "ejected object not moved back to the stage")
end
C.done()
