-- T14: the state listener is permanent; setListener swaps or clears only the function it calls (D9, D10).
-- mode = nil_in_callback | replace_in_callback | nil_then_fn_in_callback | remove_in_callback | release
-- The *_in_callback modes act on "interrupted" of walk: setAnimation(run) drains interrupted(walk) then began(run),
-- so the rest of that drain shows what the change did to the running dispatch.
local spine = require("plugin.spine")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local mode = arg[1]
local data = spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas"))
local log = {}
-- Logs lifecycle phases only: walk's footstep events land at frame-dependent points.
local function logger(tag)
  return function(ev)
    if ev.phase and ev.phase ~= "event" then log[#log + 1] = tag .. ":" .. ev.phase .. ":" .. ev.animation end
  end
end
local function seen() local out = table.concat(log, " "); print("  log:", out); return out end

-- A create() listener that runs `act` on interrupted(walk), then logs that it kept running.
local function interruptOnWalk(act)
  local s
  local record = logger("A")
  s = spine.create(data, function(ev)
    record(ev)
    if ev.phase == "interrupted" and ev.animation == "walk" then act(s); log[#log + 1] = "A:after" end
  end)
  s:setAnimation(1, "walk", true); s:updateState(16)
  s:setAnimation(1, "run", true)
  return s
end

if mode == "nil_in_callback" then
  local s = interruptOnWalk(function(s) s:setListener(nil) end)
  C.expect(seen() == "A:began:walk A:interrupted:walk A:after", "the cleared function still received events")
  for i = 1, 5 do s:updateState(16) end
  C.expect(#log == 3, "events reached a cleared listener")
  s:setListener(logger("B")) -- the listener object survived the clear: a new function is called again
  s:setAnimation(1, "idle", true)
  C.expect(seen():find("B:interrupted:run B:began:idle", 1, true) ~= nil, "no events after setListener(fn) following a clear")
elseif mode == "replace_in_callback" then
  interruptOnWalk(function(s) s:setListener(logger("B")) end)
  C.expect(seen() == "A:began:walk A:interrupted:walk A:after B:began:run",
    "the rest of the drain did not go to the replacement only")
elseif mode == "nil_then_fn_in_callback" then
  interruptOnWalk(function(s) s:setListener(nil); s:setListener(logger("B")) end)
  C.expect(seen() == "A:began:walk A:interrupted:walk A:after B:began:run",
    "a function set after a clear inside the callback missed the rest of the drain")
elseif mode == "remove_in_callback" then
  local s = interruptOnWalk(function(s) s:removeSelf() end)
  -- the removal check drops began(run), which the same drain would otherwise deliver
  C.expect(seen() == "A:began:walk A:interrupted:walk A:after", "a removed object dispatched the rest of the drain")
  C.expect(s.setAnimation == nil, "a removed object still answers setAnimation")
  __stub.frame()
  C.expect(#log == 3, "events reached the listener of a disposed object")
elseif mode == "release" then
  -- setListener releases the function it replaces or clears
  local weak = setmetatable({}, { __mode = "v" })
  local s = spine.create(data, logger("A"))
  weak.first = logger("first"); s:setListener(weak.first)
  weak.second = logger("second"); s:setListener(weak.second)
  collectgarbage(); collectgarbage()
  C.expect(weak.first == nil, "the replaced function is still referenced")
  C.expect(weak.second ~= nil, "the current function was released")
  s:setListener(nil)
  collectgarbage(); collectgarbage()
  C.expect(weak.second == nil, "the cleared function is still referenced")
  s:removeSelf(); __stub.frame()
end
print("end of script")
C.done()
