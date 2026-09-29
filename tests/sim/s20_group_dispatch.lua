-- S20 (D8, D9, D37): spine events reach the group's own dispatchEvent after the create() listener, under the real
-- init.lua EventDispatcher. The argument picks the case:
--   order         create() listener, then function listeners, then table listeners, one event table, target = obj
--   remove_create removeSelf() in the create() listener skips the group listeners for that event
--   remove_group  removeSelf() in a group listener does not stop that dispatch; no later events
--   error         errors in the create() listener and in a group listener reach unhandledError; the drain continues
--   remove_create_split, remove_group_split, remove_lua_split: the object is split and its jump loops with an
--                 onComplete; removeSelf() in the create() listener, in a group listener, or from plain Lua in the next
--                 frame takes its meshes out of the caller's split group, which stays with the caller, and no later
--                 event or onComplete reaches Lua, while a split control object keeps looping
local L = require("simlib")
L.watchdogMs = 20000
local MODE = L.arg
L.open("s20_group_dispatch " .. MODE)
local checks = {
  order = { "order", "table", "target" },
  remove_create = { "skip group", "no later events" },
  remove_group = { "rest of dispatch", "no later events" },
  error = { "unhandledError", "drain continues" },
}
local SPLIT = MODE:match("^(.+)_split$") -- the split modes run their base mode's removal on a split object
if SPLIT then checks[MODE] = { "in group", "meshes left", "group kept", "no later events", "control continues" } end
L.expect(unpack(checks[MODE]))
local spine = L.loadPlugin()
local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.3)

local log, events = {}, {}
local obj, wrongTarget = nil, 0
-- listener who after: logs "<who>:<phase>[:<spine event>]" and the event table, then calls after(ev), if given
local function listener(who, after)
  return function(ev)
    log[#log + 1] = who .. ":" .. ev.phase .. (ev.event and (":" .. ev.event) or "")
    events[#events + 1] = ev
    if ev.target ~= obj then wrongTarget = wrongTarget + 1 end
    if after then after(ev) end
  end
end
local sg, meshes -- split modes: the caller's split group, and its numChildren just before and just after removeSelf
local function remove()
  if sg then meshes = { sg.numChildren } end
  obj:removeSelf()
  if sg then meshes[2] = sg.numChildren end
end
local function removeOn(phase) return function(ev) if ev.phase == phase then remove() end end end
local pending -- remove_lua_split: the create() listener saw "completed"; the next frame removes the object
local function boom(phase, message) return function(ev) if ev.phase == phase then error(message) end end end

-- the error case's two errors are expected: simlib's unhandledError line would fail the scenario
local errors = {}
if MODE == "error" then
  local log0 = L.log
  L.log = function(tag, message, ...)
    if tag == "UNHANDLED_ERROR" and tostring(message):find("boom in ", 1, true) then tag = "EXPECTED_UNHANDLED_ERROR" end
    return log0(tag, message, ...)
  end
  Runtime:addEventListener("unhandledError", function(e) errors[#errors + 1] = tostring(e.errorMessage); return true end)
end

local create = { remove_create = removeOn("completed"), error = boom("completed", "boom in create listener"),
  remove_lua = function(ev) if ev.phase == "completed" then pending = true end end }
local group = { remove_group = removeOn("completed"), error = boom("event", "boom in group listener") }
obj = spine.create(data, listener("A", create[SPLIT or MODE]))
obj.x, obj.y = 300, 700
obj:addEventListener("spine", listener("F1", group[SPLIT or MODE]))
obj:addEventListener("spine", { spine = function(self, ev) listener("T")(ev) end })
obj:addEventListener("spine", listener("F2"))
-- began here, footstep at 1.2 s, completed at 1.33 s; a split object loops: footstep at 2.53 s, completed at 2.67 s
local jump = obj:setAnimation(1, "jump", SPLIT ~= nil)

-- the split modes' control: an unremoved split object with the same loop, logging its phases and onComplete calls
local ctl, ctlLog = nil, {}
local function half(o)
  local slots = {}
  for i, slot in ipairs(o.slots) do if i % 2 == 0 then slots[#slots + 1] = slot.name end end
  return slots
end
if SPLIT then
  jump.onComplete = listener("C")
  sg = obj:split(half(obj))
  ctl = spine.create(data, function(ev) ctlLog[#ctlLog + 1] = ev.phase end)
  ctl.x, ctl.y = 500, 700
  ctl:split(half(ctl))
  ctl:setAnimation(1, "jump", true).onComplete = function() ctlLog[#ctlLog + 1] = "onComplete" end
end

local function finish()
  local out = table.concat(log, " ")
  L.log("log", out)
  local full = "A:began F1:began F2:began T:began A:event:footstep F1:event:footstep F2:event:footstep T:event:footstep"
  if MODE == "order" then
    L.check("order", out == full .. " A:completed F1:completed F2:completed T:completed", out)
    local same = #events == 12
    for i = 1, #events, 4 do for j = i + 1, i + 3 do same = same and rawequal(events[i], events[j]) end end
    L.check("table", same, "one event table per spine event", #events)
    L.check("target", wrongTarget == 0 and #events == 12, "event.target ~= obj in " .. wrongTarget .. " calls")
  elseif MODE == "remove_create" then
    L.check("skip group", out:match("A:completed$") ~= nil, out)
    L.check("no later events", out == full .. " A:completed", out)
  elseif MODE == "remove_group" then
    L.check("rest of dispatch", out:match("A:completed F1:completed F2:completed T:completed$") ~= nil, out)
    L.check("no later events", out == full .. " A:completed F1:completed F2:completed T:completed", out)
  elseif SPLIT then
    L.check("in group", meshes ~= nil and meshes[1] > 0, "split group children before removeSelf", meshes and meshes[1])
    L.check("meshes left", meshes ~= nil and meshes[2] == 0 and sg.numChildren == 0,
      "split group children after removeSelf, at the end", meshes and meshes[2], sg.numChildren)
    L.check("group kept", sg.parent ~= nil and sg.removeSelf ~= nil, "the caller's split group is still on the stage")
    local rest = SPLIT == "remove_create" and "" or " F1:completed F2:completed T:completed"
    L.check("no later events", out == full .. " C:completed A:completed" .. rest, out)
    -- the removal came at the first completed: the control's second footstep and onComplete are later events
    local c = table.concat(ctlLog, " ")
    L.check("control continues", select(2, c:gsub("event", "")) >= 2 and select(2, c:gsub("onComplete", "")) >= 2, c)
  else
    L.check("unhandledError", #errors == 2 and errors[1]:find("boom in group listener", 1, true) ~= nil
      and errors[2]:find("boom in create listener", 1, true) ~= nil, table.concat(errors, " | "))
    L.check("drain continues", out == "A:began F1:began F2:began T:began A:event:footstep F1:event:footstep"
      .. " A:completed F1:completed F2:completed T:completed", out)
  end
  L.finish(0)
end

local n = 0
Runtime:addEventListener("enterFrame", function()
  n = n + 1
  if pending and not meshes then remove() end
  if obj.updateState then obj:updateState(1000 / 60); if obj.draw then obj:draw() end end
  if ctl then ctl:updateState(1000 / 60); ctl:draw() end
  if n == (SPLIT and 180 or 120) then finish() end
end)
