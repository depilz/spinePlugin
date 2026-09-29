-- T4: listener re-entrancy + errors inside listeners. dispose_* modes: removeSelf() inside a callback, then the frame
-- ends and the next one disposes (animation-1); the suite checks that the error mode's listener error reaches
-- CoronaLuaDoCall (animation-6).
-- mode = set_in_complete | clear_in_complete | setlistener_nil | setlistener_replace | error | error_then_more |
--        dispose_in_complete | dispose_in_event | clearTracks_in_end | nested_update
local spine = require("plugin.spine")
local mode = arg[1]
local data = spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas"))
local s
local n = 0
local function log(ev) n = n + 1; print(("  #%d %s %s %s t%d"):format(n, ev.name, tostring(ev.phase), ev.animation, ev.trackIndex)) end

if mode == "set_in_complete" then
  s = spine.create(data, function(ev)
    log(ev)
    if ev.phase == "completed" and ev.animation == "jump" then
      local e = s:setAnimation(1, "idle", true)
      print("  -> setAnimation inside 'completed' returned", e and e.animation)
    end
  end)
  s:setAnimation(1, "jump", false)
  for i = 1, 100 do s:updateState(16) end
  print("current:", s:getCurrentAnimation(1))
elseif mode == "clear_in_complete" then
  s = spine.create(data, function(ev)
    log(ev)
    if ev.phase == "completed" then s:clearTrack(1) end
  end)
  s:setAnimation(1, "jump", false)
  for i = 1, 100 do s:updateState(16) end
  print("current:", s:getCurrentAnimation(1))
elseif mode == "setlistener_nil" then
  s = spine.create(data, function(ev)
    log(ev)
    if ev.phase == "interrupted" then s:setListener(nil); print("  -> listener cleared inside callback") end
  end)
  s:setAnimation(1, "walk", true); s:updateState(16)
  s:setAnimation(1, "run", true) -- interrupt(walk) -> start(run) queued in same drain
  for i = 1, 30 do s:updateState(16) end
elseif mode == "setlistener_replace" then
  s = spine.create(data, function(ev)
    log(ev)
    if ev.phase == "interrupted" then
      s:setListener(function(ev2) print("  [new listener]", ev2.phase, ev2.animation) end)
      print("  -> listener replaced inside callback")
    end
  end)
  s:setAnimation(1, "walk", true); s:updateState(16)
  s:setAnimation(1, "run", true)
  for i = 1, 30 do s:updateState(16) end
elseif mode == "error" or mode == "error_then_more" then
  s = spine.create(data, function(ev)
    log(ev)
    if ev.phase == "interrupted" then error("boom in listener") end
  end)
  s:setAnimation(1, "walk", true); s:updateState(16)
  local ok, err = pcall(s.setAnimation, s, 1, "run", true)
  print("setAnimation that triggered listener error: pcall ok =", ok, err)
  for i = 1, 30 do s:updateState(16) end
  if mode == "error_then_more" then
    local e = s:setAnimation(1, "idle", true)
    print("subsequent setAnimation delivered events? (see log) current =", s:getCurrentAnimation(1))
  end
elseif mode == "dispose_in_complete" then
  -- Solar2D idiom: remove the object when its one-shot animation completes
  s = spine.create(data, function(ev)
    log(ev)
    if ev.phase == "completed" then print("  -> removing skeleton inside 'completed'"); s:removeSelf() end
  end)
  s:setAnimation(1, "jump", false)
  for i = 1, 100 do if s.removeSelf then s:updateState(16) end end
  __stub.frame()
  print("survived")
elseif mode == "dispose_in_event" then
  s = spine.create(data, function(ev)
    log(ev)
    if ev.event == "footstep" then print("  -> removing skeleton inside custom event"); s:removeSelf() end
  end)
  s:setAnimation(1, "walk", true)
  for i = 1, 100 do if s.removeSelf then s:updateState(16) end end
  __stub.frame()
  print("survived")
elseif mode == "clearTracks_in_end" then
  s = spine.create(data, function(ev)
    log(ev)
    if ev.phase == "ended" then s:clearTracks() end
  end)
  s:setAnimation(1, "walk", true); s:setAnimation(2, "aim", true); s:updateState(16)
  s:setAnimation(1, "run", true)
  for i = 1, 30 do s:updateState(16) end
  print("isActive", s.isActive)
elseif mode == "nested_update" then
  s = spine.create(data, function(ev)
    log(ev)
    if ev.event == "footstep" and n < 40 then s:updateState(16) end
  end)
  s:setAnimation(1, "walk", true)
  for i = 1, 60 do s:updateState(16) end
end
print("end of script")
