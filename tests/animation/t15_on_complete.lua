-- T15: entry.onComplete (D11-D14): called with the "completed" event of its own entry, before the create() listener,
-- on every loop; released with its entry and with the skeleton; never inherited by a recycled entry.
-- mode = order | release | recycled | stale | type | error | remove_in_callback | clear_in_callback
local spine = require("plugin.spine")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local mode = arg[1]
local data = spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas"))
local log = {}
local function seen() local out = table.concat(log, " "); print("  log:", out); return out end
-- A create() listener logging lifecycle phases (walk's footstep events land at frame-dependent points), then
-- passing the event to inspect, if given.
local function create(inspect)
  return spine.create(data, function(ev)
    if ev.phase and ev.phase ~= "event" then log[#log + 1] = "A:" .. ev.phase .. ":" .. ev.animation end
    if inspect then inspect(ev) end
  end)
end
local function step(s, ms) for i = 1, ms / 16 do if s.removeSelf then s:updateState(16) end end end
local function count(pattern) local n = 0; for _, e in ipairs(log) do if e == pattern then n = n + 1 end end; return n end
local function raises(f) local ok, err = pcall(f); print("  raised:", not ok, err); return not ok end
local function gc() collectgarbage(); collectgarbage() end

if mode == "order" then
  local last -- the event the latest onComplete got; the create() listener must get that same table
  local s = create(function(ev)
    if ev.phase == "completed" then C.expect(rawequal(ev, last), "the create() listener got another event table") end
  end)
  local walk = s:setAnimation(1, "walk", true)
  local jump = s:setAnimation(2, "jump", false)
  local onWalk = function(ev)
    log[#log + 1] = "O:" .. ev.phase .. ":" .. ev.animation
    last = ev
    C.expect(ev.target == s and ev.trackIndex == 1 and ev.looping == true, "onComplete got another entry's event")
  end
  walk.onComplete = onWalk
  jump.onComplete = function(ev) log[#log + 1] = "P:" .. ev.phase .. ":" .. ev.animation; last = ev end
  C.expect(walk.onComplete == onWalk, "onComplete does not read back")
  step(s, 3000)
  C.expect(walk.onComplete == onWalk, "onComplete was cleared by firing")
  s:setAnimation(1, "run", true); step(s, 32) -- walk's other phases (interrupted, ended, disposed) skip onComplete
  local out = seen()
  local loops = count("A:completed:walk")
  C.expect(loops >= 2, "walk completed fewer than 2 loops")
  C.expect(count("O:completed:walk") == loops, "walk.onComplete did not fire on every loop")
  C.expect(count("P:completed:jump") == 1 and count("A:completed:jump") == 1, "jump.onComplete did not fire once")
  C.expect(not out:find("O:completed:jump", 1, true) and not out:find("P:completed:walk", 1, true),
    "an onComplete fired for another entry")
  for i, e in ipairs(log) do
    if e:sub(1, 2) == "O:" or e:sub(1, 2) == "P:" then
      C.expect(e:find(":completed:", 1, true) ~= nil, "onComplete fired for another phase: " .. e)
      C.expect(log[i + 1] == "A" .. e:sub(2), "onComplete did not run right before the create() listener: " .. e)
    end
  end
  C.expect(count("A:disposed:walk") == 1, "walk was not disposed")
  s:removeSelf(); __stub.frame()
elseif mode == "release" then
  local weak = setmetatable({}, { __mode = "v" })
  -- the entry's dispose (end, then pool reset) releases its function
  local s = create()
  local jump = s:setAnimation(1, "jump", false)
  weak.jump = function() end; jump.onComplete = weak.jump
  step(s, 2000)
  gc()
  C.expect(weak.jump ~= nil and count("A:completed:jump") == 1, "a completed but current entry lost its onComplete")
  local idle = s:setAnimation(1, "idle", true); step(s, 32)
  C.expect(count("A:disposed:jump") == 1, "jump was not disposed")
  gc()
  C.expect(weak.jump == nil, "onComplete of a disposed entry is still referenced")
  -- replacing or clearing releases the previous function
  weak.first = function() end; idle.onComplete = weak.first
  weak.second = function() end; idle.onComplete = weak.second
  gc()
  C.expect(weak.first == nil and weak.second ~= nil, "a replaced onComplete is still referenced")
  idle.onComplete = nil
  gc()
  C.expect(weak.second == nil and idle.onComplete == nil, "a cleared onComplete is still referenced")
  s:removeSelf(); __stub.frame()
  -- the skeleton's dispose releases every entry's function (t8 style: 50 objects, 100 KB upvalue each)
  local closures = setmetatable({}, { __mode = "k" })
  for i = 1, 50 do
    local big = string.rep("x", 1e5) .. i
    local fn = function() return big end
    closures[fn] = true
    local o = spine.create(data)
    o:setAnimation(1, "walk", true).onComplete = fn
    o:setAnimation(2, "jump", false).onComplete = fn
    o:updateState(16)
    o:removeSelf()
  end
  __stub.frame(); __stub.gcfull()
  local n = 0; for _ in pairs(closures) do n = n + 1 end
  print(("alive after skeleton dispose + GC: onComplete closures %d of 50; Lua heap KB %d")
    :format(n, math.floor(collectgarbage("count"))))
  C.expect(n == 0, "onComplete closures of disposed skeletons are still referenced")
elseif mode == "recycled" then
  local s = create()
  s:setDefaultMix(200)
  local walk = s:setAnimation(1, "walk", true)
  local walkPtr = __native.entryPtr(walk)
  walk.onComplete = function() log[#log + 1] = "O:inherited" end
  s:updateState(16)
  s:setAnimation(1, "run", true)
  step(s, 320) -- > 200 ms mix: walk ended + disposed (reset + returned to the pool)
  local jump = s:setAnimation(2, "jump", false) -- obtains the pooled object
  C.expect(__native.entryPtr(jump) == walkPtr, "jump did not reuse walk's pooled TrackEntry: the test proves nothing")
  C.expect(jump.onComplete == nil, "a recycled entry reads its previous onComplete")
  step(s, 2000)
  C.expect(count("A:completed:jump") == 1, "jump did not complete")
  C.expect(count("O:inherited") == 0, "a recycled entry called its previous onComplete")
  seen()
  s:removeSelf(); __stub.frame()
elseif mode == "stale" then
  local s = create()
  s:setDefaultMix(200)
  local walk = s:setAnimation(1, "walk", true)
  walk.onComplete = function() end
  s:updateState(16)
  local run = s:setAnimation(1, "run", true)
  step(s, 320)
  C.expect(not walk.isValid, "walk is still valid")
  C.expect(raises(function() return walk.onComplete end), "reading onComplete through a stale entry did not raise")
  C.expect(raises(function() walk.onComplete = function() end end), "writing onComplete through a stale entry did not raise")
  s:removeSelf(); __stub.frame() -- the next frame disposes the skeleton and so every entry
  C.expect(raises(function() return run.onComplete end), "reading onComplete of a disposed skeleton did not raise")
  C.expect(raises(function() run.onComplete = nil end), "writing onComplete of a disposed skeleton did not raise")
elseif mode == "type" then
  local s = create()
  local walk = s:setAnimation(1, "walk", true)
  for _, v in ipairs({ 5, "f", true, {} }) do
    C.expect(raises(function() walk.onComplete = v end), "onComplete accepted a " .. type(v))
  end
  C.expect(walk.onComplete == nil, "a rejected value was stored")
  local fn = function() end
  walk.onComplete = fn; C.expect(walk.onComplete == fn, "a function did not read back")
  walk.onComplete = nil; C.expect(walk.onComplete == nil, "nil did not clear")
  s:removeSelf(); __stub.frame()
elseif mode == "error" then
  local s = create()
  s:setAnimation(1, "walk", true).onComplete = function() log[#log + 1] = "O"; error("boom in onComplete") end
  local ok, err = pcall(step, s, 3000)
  print("updateState that drained the onComplete error: pcall ok =", ok, err)
  seen()
  local loops = count("A:completed:walk")
  C.expect(ok and loops >= 2 and count("O") == loops, "the drain did not continue after an onComplete error")
  s:removeSelf(); __stub.frame()
elseif mode == "remove_in_callback" then
  -- removal inside onComplete drops the create() listener's stage for that event and the rest of the drain
  local s = create()
  local walk = s:setAnimation(1, "walk", true)
  walk.onComplete = function(ev) log[#log + 1] = "O:" .. ev.phase; s:removeSelf() end
  step(s, 3000)
  C.expect(seen() == "A:began:walk O:completed", "a removed object dispatched after its onComplete")
  __stub.frame()
  C.expect(#log == 2, "events reached a disposed object")
elseif mode == "clear_in_callback" then
  -- clearing inside onComplete releases the running function; the create() listener still gets that event
  local s = create()
  local walk = s:setAnimation(1, "walk", true)
  walk.onComplete = function(ev) log[#log + 1] = "O:" .. ev.phase; walk.onComplete = nil; collectgarbage() end
  step(s, 3000)
  local out = seen()
  C.expect(count("O:completed") == 1 and count("A:completed:walk") >= 2, "onComplete fired after being cleared")
  C.expect(out:find("O:completed A:completed:walk", 1, true) ~= nil, "the create() listener missed that event")
  s:removeSelf(); __stub.frame()
end
print("end of script")
C.done()
