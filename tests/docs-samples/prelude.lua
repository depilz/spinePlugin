-- tests/docs-samples prelude: run by tests/lifecycle/run.sh --plain after solar2d_stub.lua, it runs the docs sample
-- arg[1] with what the pages take as given, then 120 frames (2 s at 60 fps) so its timers, transitions and
-- enterFrame listeners run. Any raise fails the sample (the host exits 1); an enterFrame raise fails it in run.sh.
-- Given: both plugin names (require("plugin.spine42") and ("plugin.spine43") load the host's plugin.spine), the
-- globals spine (the plugin), spineboy (spine.create of the line's spineboy example, as the pages call it) and
-- skeleton (the spineboy object, as the syntax lines call it), and the Solar2D calls the stub lacks:
-- display.newRect/newCircle/newText/newImageRect, display.content*, timer.performWithDelay/cancel,
-- transition.to/cancel.
local S = __stub
local FRAME_MS = 1000 / 60

for _, name in ipairs({ "plugin.spine42", "plugin.spine43" }) do
  package.preload[name] = function() return require("plugin.spine") end
end

display.contentWidth, display.contentHeight = 480, 320
display.actualContentWidth, display.actualContentHeight = 480, 320
display.contentCenterX, display.contentCenterY = 240, 160

-- shape(fields...): a display.new* that takes an optional parent group, then the named positional arguments
local function shape(...)
  local fields = { ... }
  return function(parent, ...)
    local args = { ... }
    if type(parent) ~= "table" or rawget(parent, "__children") == nil then table.insert(args, 1, parent); parent = nil end
    local o = display.newGroup()
    rawset(o, "__children", nil)
    if parent then parent:insert(o) end
    if type(args[1]) == "table" then
      for k, v in pairs(args[1]) do o[k] = v end
    else
      for i, field in ipairs(fields) do o[field] = args[i] end
    end
    return o
  end
end
display.newRect = shape("x", "y", "width", "height")
display.newCircle = shape("x", "y", "radius")
display.newText = shape("text", "x", "y", "font", "fontSize")
display.newImageRect = shape("filename", "width", "height")

local clock, timers = 0, {}
timer = {}
function timer.performWithDelay(delay, listener, iterations)
  local t = { due = clock + delay, delay = delay, listener = listener, left = iterations or 1, count = 0 }
  timers[#timers + 1] = t
  return t
end
function timer.cancel(t) if type(t) == "table" then t.cancelled = true end end

transition = {}
local TRANSITION_PARAMS = { time = 1, delay = 1, transition = 1, iterations = 1, tag = 1, onStart = 1, onComplete = 1,
                            onCancel = 1, onPause = 1, onResume = 1, onRepeat = 1, delta = 1 }
function transition.to(target, params)
  for k, v in pairs(params) do if not TRANSITION_PARAMS[k] then target[k] = v end end
  local complete = params.onComplete
  if complete then timer.performWithDelay((params.delay or 0) + (params.time or 500), function() complete(target) end) end
  return { target = target }
end
function transition.cancel() end

local function fireTimers()
  for _, t in ipairs(timers) do
    if not t.cancelled and t.due <= clock and (t.left <= 0 or t.count < t.left) then
      t.count = t.count + 1
      t.due = t.due + t.delay
      local event = { name = "timer", source = t, count = t.count, time = clock }
      if type(t.listener) == "function" then t.listener(event) else t.listener:timer(event) end
    end
  end
end

spine = require("plugin.spine")
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
spineboy = spine.create(spine.loadSkeletonData("spineboy/spineboy.json", atlas))
skeleton = spineboy

assert(loadfile(arg[1]))()
for frame = 1, 120 do
  clock = frame * FRAME_MS
  fireTimers()
  S.frame()
end
