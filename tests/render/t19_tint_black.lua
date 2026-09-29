-- Tint black: a mesh carries the reserved effect filter.custom.plugin_spine_tintBlack iff its command's dark rgb is not
-- black, the effect is defined and the skeleton has no user fill effect; the effect is assigned only on transitions and
-- its r, g, b params only when the dark changes. Draws the synthetic fixture tests/sim/assets/tintblack/<line>.
-- t19_tint_black.lua mode [variant]:
--   nodark       spineboy and raptor: no define, no tint write
--   fixture      [true] two fixture skeletons: one define with the reserved name, 8 tinted meshes each, no writes once
--                steady; the define returns false like Solar2D, or true (a future engine): both are success
--   batching     no batched command merges commands whose darkColors[0] differ
--   pulse        rgba2 dark red -> blue -> black, then restarted: dark -> black -> dark, params written only on change
--   swap         a texture-page swap re-applies the tint on the new paint, also on a blended slot
--   hide         hiding and showing a slot shifts commands onto other meshes
--   split        split(), a re-split and reassemble()
--   usereffect   filter.brightness, then filter.desaturate + intensity, win over tint; tint returns on the next draw
--   nodefine     graphics.defineEffect is nil: no tint, no warning
--   definefail   the define raises: one warning per Lua state, no raise, no tint
--   duplicate    the app defined the reserved name first: the engine logs its ERROR line and returns false, the plugin
--                sees success (no warning) and draws the app's effect, the documented silent-duplicate limit
--   sharedkey    [failed] the other plugin binary already defined the effect in this Lua state (or its define raised):
--                no second define, tint on (off) without a warning
--   alpha        [inject] slot.alpha 1 -> 0 -> 1 on the tinted slot normal, on page 1 and after the swap to page 2:
--                normal draws its tint again; inject: an injected object on normal, so its placeholder sits among tints
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock, spine, fx = C.mock, C.spine, C.fx
local W = arg[0]:match("^(.*)/")
local mode, variant = arg[1], arg[2]
local NAME = "filter.custom.plugin_spine_tintBlack"
local TINTED = 8 -- fixture slots with a non-black dark at setup (all but darkblack and nodark)
local tintable = true -- false where the define raised in this Lua state: frame() expects no tint

local lines = {}
local print0 = print
function print(...) -- keeps every printed line for the warning checks
  local t = {}
  for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end
  lines[#lines + 1] = table.concat(t, "\t")
  print0(...)
end
local function warnings()
  local n = 0
  for _, l in ipairs(lines) do if l:find("^WARNING:") then n = n + 1 end end
  return n
end

local fixtureData
local function fixture()
  if not fixtureData then
    local dir = ("%s/../sim/assets/tintblack/%s/"):format(W, os.getenv("SPINE_RUNTIME") or "4.2")
    fixtureData = spine.loadSkeletonData(dir .. "tintblack.json", spine.loadAtlas(dir .. "tintblack.atlas"), 1)
  end
  return spine.create(fixtureData)
end

local function rgbOf(dark) return dark % 16777216 end
local function tintWrites(s)
  return (s["effectSet:" .. NAME] or 0) + (s["effectSet:nil"] or 0), s["effectParamSet:" .. NAME] or 0
end

-- The mesh children of the skeleton's groups paired with the commands that drew them: { mesh, command } pairs.
local function pairsOf(obj)
  local out = {}
  local main, split = fx.expected(obj)
  local function add(group, cmds)
    local meshes = {}
    for _, c in ipairs(mock.children(group)) do if mock.kind(c) == "mesh" then meshes[#meshes + 1] = c end end
    local i = 0
    for _, cmd in ipairs(cmds) do
      if cmd.numIndices >= 3 then i = i + 1; out[#out + 1] = { mesh = meshes[i], cmd = cmd } end
    end
  end
  add(obj, main)
  if split then add(obj._splitGroup, split) end
  return out
end

-- Every mesh the skeleton has drawn, in both groups
local function meshesOf(obj)
  local out = {}
  for _, g in ipairs({ obj, obj._splitGroup }) do
    for _, c in ipairs(mock.children(g)) do if mock.kind(c) == "mesh" then out[#out + 1] = c end end
  end
  return out
end

-- The tint state a mesh's paint shows: its paint table, on, and the dark rgb its params hold.
local function tintOf(mesh)
  local p = mock.paint(mesh)
  local e = p and p.effect
  if not (e and e.name == NAME) then return { paint = p, on = false } end
  local q = e.params
  local function byte(v) return math.floor((v or 0) * 255 + 0.5) end
  return { paint = p, on = true, rgb = byte(q.r) * 65536 + byte(q.g) * 256 + byte(q.b) }
end

local stats = { frames = 0, sets = 0, params = 0, tinted = 0 }
-- Draws one frame and checks every mesh against its command. The expected tint writes are the minimum: one effect write
-- per mesh whose tint state changed (a new paint starts without effect), three params per mesh whose tint turned on or
-- whose dark changed. userEffect: the skeleton's user effect name (no mesh may carry tint, every mesh carries it).
local function frame(obj, label, dt, userEffect)
  local before = {}
  for _, m in ipairs(meshesOf(obj)) do before[m] = tintOf(m) end
  mock.resetStats()
  C.frame(obj, dt)
  local sets, params = tintWrites(mock.stats)
  local wantSets, wantParams, tinted = 0, 0, 0
  for i, pr in ipairs(pairsOf(obj)) do
    local rgb = rgbOf(pr.cmd.dark)
    local want = rgb ~= 0 and not userEffect and tintable and graphics.defineEffect ~= nil
    local now, old = tintOf(pr.mesh), before[pr.mesh]
    local oldOn = old and old.paint == now.paint and old.on
    if now.on ~= want then C.expect(false, ("%s #%d: tint %s, expected %s (dark %06x)"):format(label, i, tostring(now.on), tostring(want), rgb)) end
    if want and now.rgb ~= rgb then C.expect(false, ("%s #%d: params %06x, expected %06x"):format(label, i, now.rgb or -1, rgb)) end
    if userEffect then
      local e = mock.paint(pr.mesh).effect
      C.expect(e and e.name == userEffect, ("%s #%d: effect %s, expected the user effect %s"):format(label, i, tostring(e and e.name), userEffect))
    end
    if now.on ~= (oldOn or false) then wantSets = wantSets + 1 end
    if now.on and (not oldOn or old.rgb ~= now.rgb) then wantParams = wantParams + 3 end
    if now.on then tinted = tinted + 1 end
  end
  C.expect(sets == wantSets, ("%s: %d tint effect writes, expected %d (transitions only)"):format(label, sets, wantSets))
  C.expect(params == wantParams, ("%s: %d tint param writes, expected %d (changes only)"):format(label, params, wantParams))
  stats.frames, stats.sets, stats.params = stats.frames + 1, stats.sets + sets, stats.params + params
  return tinted, sets, params
end

local function defines() return #mock.defines end

if mode == "nodark" then
  for _, name in ipairs({ "spineboy", "raptor" }) do
    local obj = spine.create(C.data(name, 0.5))
    for _, anim in ipairs(obj:getAnimations()) do
      obj:setAnimation(1, anim, true)
      for f = 1, 20 do frame(obj, name .. " " .. anim .. " " .. f) end
    end
    obj:removeSelf()
  end
  print(("nodark: frames=%d defines=%d tint writes=%d"):format(stats.frames, defines(), stats.sets + stats.params))
  C.expect(defines() == 0, "graphics.defineEffect called for skeletons without a non-black dark")
  C.expect(stats.sets + stats.params == 0, "tint writes for skeletons without a non-black dark")

elseif mode == "fixture" then
  if variant == "true" then mock.defineReturns = true end
  local a, b = fixture(), fixture()
  for f = 1, 3 do
    local ta, sa, pa = frame(a, "a " .. f)
    local tb, sb, pb = frame(b, "b " .. f)
    print(("frame %d: tinted %d/%d, tint writes %d/%d"):format(f, ta, tb, sa + pa, sb + pb))
    C.expect(ta == TINTED and tb == TINTED, "tinted meshes per fixture skeleton")
    if f > 1 then C.expect(sa + pa + sb + pb == 0, "tint writes on a steady frame") end
  end
  local d = mock.defines[1]
  print(("defines=%d: category=%s group=%s name=%s vertexData=%d"):format(defines(), d.category, d.group, d.name, #d.vertexData))
  C.expect(defines() == 1, "one define per Lua state")
  C.expect(("%s.%s.%s"):format(d.category, d.group, d.name) == NAME, "the reserved effect name")
  for i, n in ipairs({ "r", "g", "b" }) do
    C.expect(d.vertexData[i].name == n and d.vertexData[i].index == i - 1, "vertexData " .. n)
  end
  C.expect(d.fragment:find("CoronaVertexUserData.rgb", 1, true) and d.fragment:find("tex.a - tex.rgb", 1, true), "the PMA-branch kernel")
  C.expect(#mock.warnings == 0 and warnings() == 0, "no warning")

elseif mode == "batching" then
  local obj = fixture()
  local function commands()
    local out = {}
    for _, c in ipairs((fx.expected(obj))) do if c.numIndices >= 3 then out[#out + 1] = c end end
    return out
  end
  -- darkblack and nodark share light, blend and page and both have a black dark: the batcher merges them
  local cmds = commands()
  local merged = 0
  for _, c in ipairs(cmds) do if c.numIndices == 12 and rgbOf(c.dark) == 0 then merged = merged + 1 end end
  print(("setup: %d commands, %d merged dark-black pair"):format(#cmds, merged))
  C.expect(#cmds == 9 and merged == 1, "the batcher merges adjacent commands with equal light and dark (control)")
  -- black light on nodark and swap: nodark, lightblack, swap now differ only in their dark
  for _, name in ipairs({ "nodark", "swap" }) do local s = obj:getSlot(name); s.r, s.g, s.b = 0, 0, 0 end
  frame(obj, "black light")
  cmds = commands()
  local bad = 0
  for i = 2, #cmds do
    local p, c = cmds[i - 1], cmds[i]
    if p.color == c.color and p.blend == c.blend and p.tex == c.tex and p.dark == c.dark then bad = bad + 1 end
  end
  for _, c in ipairs(cmds) do if c.numIndices ~= 6 then bad = bad + 1 end end
  print(("black light: %d commands, %d merged or mergeable"):format(#cmds, bad))
  C.expect(#cmds == 10 and bad == 0, "a batched command merged commands whose darkColors[0] differ")

elseif mode == "pulse" then
  local obj = fixture()
  local ons, offs = 0, 0
  local function run(label, n)
    for f = 1, n do
      local t0 = tintOf(pairsOf(obj)[2].mesh).on -- slot pulse is the second command
      frame(obj, label .. " " .. f, 50)
      local t1 = tintOf(pairsOf(obj)[2].mesh).on
      if t1 and not t0 then ons = ons + 1 elseif t0 and not t1 then offs = offs + 1 end
    end
  end
  frame(obj, "setup")                         -- setup pose: red, tint on
  obj:setAnimation(1, "pulse", false)
  run("pulse", 45)                            -- 2.25 s: red -> blue -> black, held
  local held0 = stats.params
  run("held", 5)
  C.expect(stats.params == held0, "param writes while the dark holds")
  obj:setAnimation(1, "pulse", false)         -- black -> red again
  run("restart", 10)
  print(("pulse: frames=%d effect writes=%d param writes=%d, pulse mesh on->off %d, off->on %d"):format(stats.frames, stats.sets, stats.params, offs, ons))
  C.expect(offs == 1 and ons == 1, "dark -> black -> dark clears and re-applies the tint once each")

elseif mode == "swap" then
  local obj = fixture()
  frame(obj, "setup")
  obj:setAnimation(1, "swap", false)
  local fills = 0
  for f = 1, 40 do frame(obj, "swap " .. f, 25); fills = fills + (mock.stats.fillSet or 0) end
  local swap = obj:getSlot("swap")
  C.expect(swap.attachment and swap.attachment.name == "tex2", "the swap animation reached page 2")
  -- the same page swap on a blended tinted slot
  obj:getSlot("additive").attachment = swap.attachment
  frame(obj, "additive swap")
  fills = fills + (mock.stats.fillSet or 0)
  local errs = C.check(obj, "additive swap")
  for _, e in ipairs(errs) do print("  " .. e) end
  C.expect(#errs == 0, "blend, colour or texture wrong after the swap")
  print(("swap: texture swaps=%d effect writes=%d param writes=%d"):format(fills, stats.sets, stats.params))
  C.expect(fills == 2, "two texture swaps")

elseif mode == "hide" then
  local obj = fixture()
  frame(obj, "shown")
  for _, name in ipairs({ "normal", "darkblack", "alpha" }) do
    local slot = obj:getSlot(name)
    local att = slot.attachment
    slot.attachment = nil
    frame(obj, "hidden " .. name)
    slot.attachment = att
    frame(obj, "shown " .. name)
  end
  print(("hide: frames=%d effect writes=%d param writes=%d"):format(stats.frames, stats.sets, stats.params))
  C.expect(stats.sets > 0, "hiding a slot moves tint between meshes")

elseif mode == "split" then
  local obj = fixture()
  frame(obj, "whole")
  obj._splitGroup = obj:split({ "normal", "additive", "nodark", "swap" })
  for f = 1, 3 do frame(obj, "split " .. f) end
  obj:split({ "pulse", "darkblack", "lightblack" })
  for f = 1, 3 do frame(obj, "re-split " .. f) end
  obj:reassemble(); obj._splitGroup = nil
  for f = 1, 3 do frame(obj, "reassembled " .. f) end
  local errs = C.check(obj, "reassembled")
  C.expect(#errs == 0, "meshes wrong after reassemble: " .. tostring(errs[1]))
  print(("split: frames=%d effect writes=%d param writes=%d"):format(stats.frames, stats.sets, stats.params))

elseif mode == "usereffect" then
  local obj = fixture()
  C.expect(frame(obj, "tinted") == TINTED, "tinted before the user effect")
  obj.fill.effect = "filter.brightness"
  frame(obj, "brightness", nil, "filter.brightness")
  obj.fill.effect = nil
  C.expect(frame(obj, "brightness cleared") == TINTED, "tint back on the first draw after the clear")
  obj.fill.effect = "filter.desaturate"
  obj.fill.effect.intensity = 0.5
  obj:setAnimation(1, "swap", false)          -- a texture swap while the user effect is set gets the user effect
  for f = 1, 30 do frame(obj, "desaturate " .. f, 25, "filter.desaturate") end
  for i, pr in ipairs(pairsOf(obj)) do
    local e = mock.paint(pr.mesh).effect
    C.expect(e and e.params.intensity == 0.5, ("desaturate #%d: intensity %s"):format(i, tostring(e.params.intensity)))
  end
  obj.fill.effect = nil
  C.expect(frame(obj, "desaturate cleared") == TINTED, "tint back on the first draw after the clear")
  print(("usereffect: frames=%d effect writes=%d param writes=%d"):format(stats.frames, stats.sets, stats.params))

elseif mode == "nodefine" then
  graphics.defineEffect = nil
  local a, b = fixture(), fixture()
  for f = 1, 3 do frame(a, "a " .. f); frame(b, "b " .. f) end
  print(("nodefine: tint writes=%d warnings=%d"):format(stats.sets + stats.params, warnings()))
  C.expect(stats.sets + stats.params == 0 and warnings() == 0, "tint or a warning without graphics.defineEffect")

elseif mode == "definefail" then
  local define = graphics.defineEffect
  graphics.defineEffect = function(params) define(params); error("kernel compile failed") end
  tintable = false
  local ok, err = pcall(function()
    local a, b = fixture(), fixture()
    for f = 1, 3 do frame(a, "a " .. f); frame(b, "b " .. f) end
  end)
  print(("definefail: raised=%s defines=%d tint writes=%d warnings=%d"):format(tostring(not ok), defines(), stats.sets + stats.params, warnings()))
  C.expect(ok, "a failed define raised: " .. tostring(err))
  C.expect(defines() == 1, "the failed define is not retried")
  C.expect(stats.sets + stats.params == 0, "tint writes after a failed define")
  C.expect(warnings() == 1, "one warning per Lua state")

elseif mode == "duplicate" then
  graphics.defineEffect({ category = "filter", group = "custom", name = "plugin_spine_tintBlack", fragment = "app" })
  local a, b = fixture(), fixture()
  for f = 1, 3 do
    C.expect(frame(a, "a " .. f) == TINTED and frame(b, "b " .. f) == TINTED, "tinted with the app's effect")
  end
  print(("duplicate: defines=%d engine lines=%d warnings=%d"):format(defines(), #mock.warnings, warnings()))
  C.expect(defines() == 2, "the plugin defines once after the app")
  C.expect(#mock.warnings == 1 and mock.warnings[1]:find("(custom.plugin_spine_tintBlack) for category (filter)", 1, true),
    "one engine ERROR line for the duplicate name")
  C.expect(warnings() == 0, "a plugin warning for a duplicate define")

elseif mode == "sharedkey" then
  -- what the other plugin binary's define leaves in this Lua state: true, or false when its define raised
  tintable = variant ~= "failed"
  debug.getregistry().plugin_spine_tintBlack = tintable
  local a, b = fixture(), fixture()
  for f = 1, 3 do frame(a, "a " .. f); frame(b, "b " .. f) end
  print(("sharedkey %s: defines=%d tint writes=%d warnings=%d"):format(variant or "defined", defines(), stats.sets + stats.params, warnings()))
  C.expect(defines() == 0, "defined again although the other plugin binary defined it")
  C.expect(warnings() == 0, "a warning for the other plugin binary's define")

elseif mode == "alpha" then
  local obj = fixture()
  local normal = obj:getSlot("normal")
  C.expect(obj:getDrawOrder()[1] == "normal", "normal draws first")
  if variant == "inject" then obj:inject(display.newRect(0, 0, 5, 5), "normal") end
  local placeholders = 0
  local function cycle(label)
    frame(obj, label .. " shown")
    normal.alpha = 0
    for f = 1, 2 do
      frame(obj, label .. " hidden " .. f)
      for _, c in ipairs((fx.expected(obj))) do
        if c.injectionSlot >= 0 and c.numVertices == 0 then placeholders = placeholders + 1 end
      end
    end
    normal.alpha = 1
    for f = 1, 2 do frame(obj, label .. " re-shown " .. f) end
    local t = tintOf(pairsOf(obj)[1].mesh)
    C.expect(t.on and t.rgb == 0x3399ff, ("%s: normal's tint %s, expected 3399ff"):format(label, t.on and ("%06x"):format(t.rgb) or "off"))
  end
  cycle("page 1")
  obj:setAnimation(1, "swap", false)
  for f = 1, 40 do frame(obj, "swap " .. f, 25) end
  C.expect(obj:getSlot("swap").attachment.name == "tex2", "the swap animation reached page 2")
  cycle("page 2")
  print(("alpha %s: frames=%d effect writes=%d param writes=%d placeholders=%d"):format(variant or "plain", stats.frames, stats.sets, stats.params, placeholders))
  C.expect(placeholders == (variant == "inject" and 4 or 0), "a placeholder on every hidden frame with the injection, none without")

else
  error("unknown mode " .. tostring(mode))
end
C.done()
