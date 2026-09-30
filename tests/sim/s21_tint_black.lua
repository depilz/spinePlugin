-- S21 (I9): tint black in the real renderer. The tintblack fixture (tests/sim/assets/tintblack, staged by suite.sh as
-- tintblack/<line>/) is drawn at scale 1 on an opaque background and captured with display.save after each step of a
-- sequence; suite.sh then runs s21_tint_black.py over the captures, which checks every texel block against Spine's
-- tint-black formula composited with the slot's blend and records the CHECK lines this script EXPECTs.
--   pixels: setup; a brightness hit flash and its clear; the app's desaturate + intensity pattern and its clear; the
--           rgba2 pulse mid-key, at black and back; a page swap on a normal and an additive slot and back; hide and
--           unhide; split and reassemble.
--   both:   the line's plugin loaded, then the other line's refused by the sibling guard (one Spine plugin per app,
--           D191: two lines in one Lua state are guarded, not supported); the line's plugin draws its fixture.
-- CHECK guard: requiring the other line's plugin failed with the guard's message naming both plugins.
-- CHECK define: graphics.defineEffect ran exactly once in the Lua state.
-- A capture is logged as "CAPTURE name file bgW bgH ox oy": content units, (ox, oy) the skeleton origin relative to
-- the background's top left; display.save's image of that background is bgW x bgH scaled by the display's pixel scale.
local L = require("simlib")
L.watchdogMs = 30000
L.open("s21_tint_black " .. L.arg)
local STEPS = {
  pixels = { "setup", "flash", "flashclear", "desat", "desat1", "desatclear", "pulse", "pulseblack", "pulseback",
    "swap", "swapback", "hide", "unhide", "split", "reassemble" },
  both = { "line" },
}
L.expect("define", "sampling", "log", unpack(STEPS[L.arg]))
if L.arg == "both" then L.expect("guard") end
if L.arg == "pixels" then L.expect("discriminates", "nodark") end

local defines = 0
local defineEffect = graphics.defineEffect
graphics.defineEffect = function(...)
  defines = defines + 1
  return defineEffect(...)
end

local BG, BW, BH = { 40, 80, 120 }, 480, 740
L.log("content", display.contentWidth, display.contentHeight, "pixel", display.pixelWidth, display.pixelHeight,
  "contentScale", display.contentScaleX, display.contentScaleY)

local function lineOf(plugin)
  local major, minor = plugin:match("(%d)(%d)$")
  return major .. "." .. minor
end

-- a background group at the content centre with the line's fixture skeleton on it, drawn at its setup pose
local function stage(spine, line)
  local g = display.newGroup()
  local bg = display.newRect(g, display.contentCenterX, display.contentCenterY, BW, BH)
  bg:setFillColor((BG[1] + 0.5) / 255, (BG[2] + 0.5) / 255, (BG[3] + 0.5) / 255)
  local atlas = spine.loadAtlas(("tintblack/%s/tintblack.atlas"):format(line))
  local obj = spine.create(spine.loadSkeletonData(("tintblack/%s/tintblack.json"):format(line), atlas, 1))
  g:insert(obj)
  obj.x, obj.y = display.contentCenterX, display.contentCenterY
  obj:updateState(0)
  obj:draw()
  return g, obj, atlas
end

local function capture(g, name)
  local file = ("s21_%s_%s.png"):format(L.arg, name)
  display.save(g, { filename = file, baseDir = system.TemporaryDirectory, captureOffscreenArea = true,
    isFullResolution = true })
  local src = assert(io.open(system.pathForFile(file, system.TemporaryDirectory), "rb"))
  local bytes = src:read("*a")
  src:close()
  local dst = assert(io.open(L.dir .. "/" .. file, "wb"))
  dst:write(bytes)
  dst:close()
  L.log("CAPTURE", name, file, BW, BH, BW / 2, BH / 2)
end

local jobs = {}
if L.arg == "pixels" then
  local spine = L.loadPlugin()
  local g, obj = stage(spine, lineOf(L.plugin))
  local slot = function(name) return obj:getSlot(name) end
  local sg
  local steps = {
    setup = function() end,
    flash = function() obj.fill.effect = "filter.brightness"; obj.fill.effect.intensity = 0.3 end,
    flashclear = function() obj.fill.effect = nil end,
    desat = function() obj.fill.effect = "filter.desaturate"; obj.fill.effect.intensity = 0.5 end,
    desat1 = function() obj.fill.effect.intensity = 1 end,
    desatclear = function() obj.fill.effect = nil end,
    pulse = function() obj:setAnimation(1, "pulse", false); obj:updateState(500) end,
    pulseblack = function() obj:updateState(1500) end,
    pulseback = function() obj:setAnimation(1, "pulse", false) end,
    swap = function() slot("swap").attachment = "tex2"; slot("additive").attachment = slot("swap").attachment end,
    swapback = function() slot("swap").attachment = "tex"; slot("additive").attachment = "tex" end,
    hide = function() slot("normal").attachment = nil end,
    unhide = function() slot("normal").attachment = "tex" end,
    split = function()
      sg = obj:split({ "normal", "multiply", "nodark", "lightblack" })
      g:insert(sg)
      sg.x, sg.y = obj.x, obj.y
    end,
    reassemble = function() obj:reassemble() end,
  }
  for _, name in ipairs(STEPS.pixels) do
    jobs[#jobs + 1] = function()
      steps[name]()
      obj:updateState(0)
      obj:draw()
      capture(g, name)
    end
  end
else
  local spine = L.loadPlugin()
  local other = L.plugin == "plugin.spine42" and "plugin.spine43" or "plugin.spine42"
  local ok, err = pcall(require, other)
  local want = ("%s cannot load: %s is already loaded in this app. Use only one Spine plugin per app."):format(other,
    L.plugin)
  L.check("guard", not ok and tostring(err):find(want, 1, true) ~= nil, "require('" .. other .. "')", ok, tostring(err))
  local g = stage(spine, lineOf(L.plugin))
  jobs[1] = function() capture(g, "line") end
end

local i = 0
local function nextJob()
  i = i + 1
  if jobs[i] then
    local ok, err = pcall(jobs[i])
    if not ok then L.log("ERROR", "job", i, err) end
    timer.performWithDelay(50, nextJob)
  else
    L.check("define", defines == 1, "graphics.defineEffect calls", defines)
    L.finish(0)
  end
end
timer.performWithDelay(100, nextJob)
