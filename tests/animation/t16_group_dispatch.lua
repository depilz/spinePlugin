-- T16: group dispatch (D8, D9): after the create() listener, every spine event reaches the group's own dispatchEvent,
-- function listeners then table listeners, all with one event table whose target is the object.
-- mode = order | group_only | remove_in_listener | remove_in_group | error | create_only
--   | remove_in_listener_split | remove_in_group_split (the base mode's removal on a split object whose jump loops
--     with an onComplete; its meshes leave the caller's split group, which stays with the caller, and no later event
--     or onComplete reaches Lua)
local spine = require("plugin.spine")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local mode = arg[1]
local SPLIT = mode:match("^(.+)_split$")
local data = spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas"))
local log = {}
local function seen() local out = table.concat(log, " "); print("  log:", out); return out end
local sg, meshes -- split modes: the caller's split group, and its numChildren just before and just after removeSelf
local function step(s, ms)
  for i = 1, ms / 16 do if s.removeSelf then s:updateState(16); if sg and s.draw then s:draw() end end end
end
local function remove(s)
  if sg then meshes = { sg.numChildren } end
  s:removeSelf()
  if sg then meshes[2] = sg.numChildren end
end
-- A listener logging "<who>:<phase>" (phase "event" as "event:<spine event name>"), then calling then(ev), if given.
local function logger(who, after)
  return function(ev)
    log[#log + 1] = who .. ":" .. ev.phase .. (ev.event and (":" .. ev.event) or "")
    if after then after(ev) end
  end
end
-- A split mode's jump: loops with an onComplete logging "C:completed", and the caller holds a split group of every
-- other slot; not split, it plays once. The completed that removes is at 1.33 s, a second loop's footstep at 2.53 s.
local function jump(s)
  if not SPLIT then s:setAnimation(1, "jump", false); return 1500 end
  s:setAnimation(1, "jump", true).onComplete = logger("C")
  local slots = {}
  for i, slot in ipairs(s.slots) do if i % 2 == 0 then slots[#slots + 1] = slot.name end end
  sg = s:split(slots)
  display.newGroup():insert(sg)
  s:draw()
  return 3000
end
-- the split modes' checks, after the frame that finalizes the removed object; rest: the group stage's log of the
-- removing completed
local function splitChecks(rest)
  C.expect(meshes ~= nil and meshes[1] > 0, "the split group had no meshes before removeSelf")
  C.expect(meshes ~= nil and meshes[2] == 0 and sg.numChildren == 0, "meshes stayed in the caller's split group")
  C.expect(not __stub.isRemoved(sg) and sg.parent ~= nil, "the caller's split group went with the object")
  C.expect(seen() == "A:began F1:began F2:began T:began A:event:footstep F1:event:footstep F2:event:footstep"
    .. " T:event:footstep C:completed A:completed" .. rest, "an event or onComplete reached a removed object")
end
-- s gets the group listeners F1, T, F2, registered interleaved; T is a table listener.
local function addGroupListeners(s, f1, f2, t)
  s:addEventListener("spine", f1 or logger("F1"))
  s:addEventListener("spine", { spine = function(self, ev) (t or logger("T"))(ev) end })
  s:addEventListener("spine", f2 or logger("F2"))
end

if mode == "order" then
  -- jump: began (inside setAnimation), footstep at 1.2 s, completed at 1.33 s
  local s
  local events, wrongTarget = {}, 0
  local function same(who)
    return function(ev)
      events[#events + 1] = ev
      if not rawequal(ev.target, s) then wrongTarget = wrongTarget + 1 end
      C.expect(ev.seenBy == "A", who .. " did not see the create() listener's mutation")
    end
  end
  s = spine.create(data, logger("A", function(ev) ev.seenBy = "A"; events[#events + 1] = ev end))
  addGroupListeners(s, logger("F1", same("F1")), logger("F2", same("F2")), logger("T", same("T")))
  s:setAnimation(1, "jump", false)
  step(s, 1500)
  C.expect(seen() == "A:began F1:began F2:began T:began A:event:footstep F1:event:footstep F2:event:footstep"
    .. " T:event:footstep A:completed F1:completed F2:completed T:completed",
    "the stages did not run as create(), then group functions, then group tables")
  for i = 1, #events, 4 do
    for j = i + 1, i + 3 do C.expect(rawequal(events[i], events[j]), "a stage got another event table") end
  end
  C.expect(#events == 12 and wrongTarget == 0, "event.target was not the object in every group listener")
  s:removeSelf(); __stub.frame()
elseif mode == "group_only" then
  -- no create() listener, then setListener(fn) and setListener(nil): the group keeps getting every event
  local s = spine.create(data)
  addGroupListeners(s)
  s:setAnimation(1, "jump", false)
  C.expect(seen() == "F1:began F2:began T:began", "a group without a create() listener got no events")
  s:setListener(logger("A"))
  s:setListener(nil)
  step(s, 1500)
  C.expect(seen() == "F1:began F2:began T:began F1:event:footstep F2:event:footstep T:event:footstep"
    .. " F1:completed F2:completed T:completed", "setListener(nil) stopped group dispatch")
  s:removeSelf(); __stub.frame()
elseif (SPLIT or mode) == "remove_in_listener" then
  -- removal inside the create() listener skips the group stage for that event and drops the rest of the drain
  local s
  s = spine.create(data, logger("A", function(ev) if ev.phase == "completed" then remove(s) end end))
  addGroupListeners(s)
  step(s, jump(s))
  C.expect(seen():match("A:completed$") ~= nil, "a group listener got the event its create() listener removed on")
  __stub.frame(); __stub.gcfull()
  C.expect(log[#log] == "A:completed", "events reached a disposed object")
  if SPLIT then splitChecks("") end
elseif (SPLIT or mode) == "remove_in_group" then
  -- removal inside a group listener does not stop that one dispatch (Solar2D finalizes at the end of the frame);
  -- the rest of the drain is dropped
  local s
  s = spine.create(data, logger("A"))
  addGroupListeners(s, logger("F1", function(ev) if ev.phase == "completed" then remove(s) end end))
  step(s, jump(s))
  C.expect(seen():match("A:completed F1:completed F2:completed T:completed$") ~= nil,
    "a removal inside a group listener stopped the rest of its dispatch")
  __stub.frame(); __stub.gcfull()
  C.expect(log[#log] == "T:completed", "events reached a removed object")
  if SPLIT then splitChecks(" F1:completed F2:completed T:completed") end
elseif mode == "error" then
  -- an error in the create() listener still lets the group stage run; an error in a group listener ends that
  -- dispatch (dispatchEvent has no pcall), is reported, and the drain continues
  local s = spine.create(data, logger("A", function(ev) if ev.phase == "completed" then error("boom in create listener") end end))
  addGroupListeners(s, logger("F1", function(ev) if ev.phase == "event" then error("boom in group listener") end end))
  s:setAnimation(1, "jump", false)
  local ok, err = pcall(step, s, 1500)
  print("updateState that drained the group listener error: pcall ok =", ok, err)
  C.expect(ok and seen() == "A:began F1:began F2:began T:began A:event:footstep F1:event:footstep A:completed"
    .. " F1:completed F2:completed T:completed", "a stage error stopped a later stage or the drain")
  s:removeSelf(); __stub.frame()
elseif mode == "create_only" then
  -- #14: with only a create() listener the group stage is skipped, so the group's dispatchEvent never sees a "spine"
  -- event. The counting wrapper is rawset: a plain assignment lands in the stub's __props, which __index reads after
  -- the methods, so the plugin would never find it. Only "spine" counts: finalize goes through the same field.
  local s = spine.create(data, logger("A"))
  local dispatch, spines = s.dispatchEvent, 0
  rawset(s, "dispatchEvent", function(self, ev)
    if ev.name == "spine" then spines = spines + 1 end
    return dispatch(self, ev)
  end)
  s:setAnimation(1, "jump", false)
  step(s, 1500)
  C.expect(seen() == "A:began A:event:footstep A:completed", "the create() listener did not get every event")
  C.expect(spines == 0, "a group with no spine listener was dispatched to: " .. spines)
  -- the wrapper is the one the plugin calls: with a group listener, the next jump's interrupted and began count
  s:addEventListener("spine", logger("F1"))
  s:setAnimation(1, "jump", false)
  C.expect(seen():match(" A:interrupted F1:interrupted A:began F1:began$") ~= nil and spines == 2,
    "the plugin did not dispatch through the wrapper: " .. spines)
  s:removeSelf(); __stub.frame()
end
print("end of script")
C.done()
