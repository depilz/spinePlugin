-- S1: lifecycle of a spine object removed indirectly (parent group / composer scene) in the REAL Simulator.
local L = require("simlib")
L.watchdogMs = 40000
local LATE_CALL = L.arg == "late"
L.open(LATE_CALL and "s1c_late_removeSelf" or "s1_lifecycle")
local spine = L.loadPlugin()
local composer = require("composer")
local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.3)
_G.S1 = { spine = spine, data = data, L = L }

local frame = 0
Runtime:addEventListener("enterFrame", function() frame = frame + 1 end)

-- instrument one spine object: finalize listener, logging removeSelf wrapper, weak refs
local function instrument(label, obj)
  local rec = { label = label, finalize = 0, wrapper = 0 }
  obj:addEventListener("finalize", function(e)
    rec.finalize = rec.finalize + 1
    rec.finalizeFrame = frame
    rec.finalizeTargetIsObj = (e.target == rec.weak.obj)
    rec.skelAtFinalize = type(rawget(e.target, "_skeleton"))
  end)
  local orig = obj.removeSelf           -- resolves to the plugin's C removeSelf via the SpineObject metatable
  rec.origIsC = (type(orig) == "function") and (debug.getinfo(orig, "S").what == "C")
  obj.removeSelf = function(self, ...)
    rec.wrapper = rec.wrapper + 1
    return orig(self, ...)
  end
  rec.wrapperStoredRaw = (rawget(obj, "removeSelf") ~= nil)
  rec.weak = setmetatable({}, { __mode = "v" })
  rec.weak.obj = obj
  rec.weak.skel = rawget(obj, "_skeleton")
  rec.skelType = type(rec.weak.skel)
  return rec
end
_G.S1.instrument = instrument

local leaked = {}
local function report(rec)
  collectgarbage("collect"); collectgarbage("collect")
  local o = rec.weak.obj
  L.log(rec.label,
    "finalize_fired=" .. rec.finalize .. (rec.finalizeFrame and ("@frame+" .. (rec.finalizeFrame - (rec.removedFrame or 0))) or ""),
    "finalize_target_is_obj=" .. tostring(rec.finalizeTargetIsObj),
    "_skeleton_at_finalize=" .. tostring(rec.skelAtFinalize),
    "plugin_removeSelf_wrapper_ran=" .. rec.wrapper,
    "_skeleton_userdata_alive_after_2xGC=" .. tostring(rec.weak.skel ~= nil),
    "obj_table_alive_after_2xGC=" .. tostring(o ~= nil),
    "obj_metatable_after=" .. tostring(o and getmetatable(o) ~= nil),
    "obj_rawget_skeleton_after=" .. tostring(o and type(rawget(o, "_skeleton"))),
    "obj_proxy_after=" .. tostring(o and type(rawget(o, "_proxy"))))
  if rec.weak.skel ~= nil then leaked[#leaked + 1] = rec.label:sub(1, 1) end
end

local function newSpine(parent)
  local obj = spine.create(data)
  parent:insert(obj)
  obj.x, obj.y = 200, 400
  obj:setAnimation(1, "walk", true)
  obj:updateState(16); obj:draw()
  return obj
end

local recs = {}
local steps = {}
local function wait(ms, fn) steps[#steps + 1] = { ms = ms, fn = fn } end
local function run(i)
  i = i or 1
  local s = steps[i]; if not s then return end
  timer.performWithDelay(s.ms, function()
    local ok, err = pcall(s.fn)
    if not ok then L.log("ERROR", "step", i, err) end
    run(i + 1)
  end)
end

-- A: control, explicit obj:removeSelf()
wait(50, function()
  local parent = display.newGroup()
  local obj = newSpine(parent)
  local rec = instrument("A explicit obj:removeSelf()", obj)
  rec.removedFrame = frame
  obj:removeSelf()
  rec.immediate = { mt = getmetatable(obj) ~= nil, skel = type(rawget(obj, "_skeleton")) }
  L.log("A immediately after removeSelf: metatable?", rec.immediate.mt, "_skeleton", rec.immediate.skel)
  recs.A = rec
  parent:removeSelf()
end)
-- B: display.remove(parent)
wait(50, function()
  local parent = display.newGroup()
  local obj = newSpine(parent)
  local rec = instrument("B display.remove(parent)", obj)
  rec.removedFrame = frame
  display.remove(parent)
  L.log("B immediately after display.remove(parent): finalize so far", rec.finalize, "obj.parent", tostring(obj.parent), "metatable?", getmetatable(obj) ~= nil, "_skeleton", type(rawget(obj, "_skeleton")))
  recs.B = rec
end)
-- C: parent:removeSelf(), then a LATE explicit cleanup attempt after finalize
wait(50, function()
  local parent = display.newGroup()
  local obj = newSpine(parent)
  local rec = instrument("C parent:removeSelf() then late obj:removeSelf()", obj)
  rec.removedFrame = frame
  rec.strong = obj -- keep the table so user code could try a late cleanup
  parent:removeSelf()
  recs.C = rec
end)
-- wait > 32 frames so Scene::Collect runs OnCollectUnreachables (Rtt_Scene.cpp:103-122)
wait(1500, function()
  L.log("frames elapsed", frame)
  report(recs.A); report(recs.B)
  local o = recs.C.weak.obj
  if o then
    L.log("C before late cleanup: finalize_fired", recs.C.finalize, "type(o.removeSelf)", type(rawget(o, "removeSelf")))
    L.log("C after finalize: getmetatable(o)", tostring(getmetatable(o)), "rawget _skeleton", type(rawget(o, "_skeleton")), "o.removeSelf via raw wrapper", type(rawget(o, "removeSelf")))
    if not LATE_CALL then L.log("C late call skipped in this run (see s1_lifecycle late)"); o = nil; recs.C.strong = nil; report(recs.C); return end
    L.log("C calling the plugin removeSelf on the finalized table inside pcall ...")
    local ok, err = pcall(function() o:removeSelf() end)
    L.log("C late o:removeSelf() (our raw-stored wrapper -> plugin C removeSelf) after finalize -> ok", ok, err, "wrapper ran", recs.C.wrapper)
    L.log("C after late call: rawget _skeleton", type(rawget(o, "_skeleton")), "getmetatable(o)", tostring(getmetatable(o)))
  end
  o = nil; recs.C.strong = nil
  report(recs.C)
end)
-- D: composer.gotoScene + composer.removeScene
wait(50, function()
  composer.gotoScene("sceneA")
end)
wait(500, function()
  composer.gotoScene("sceneB")
end)
wait(300, function()
  local rec = _G.S1.sceneRec
  rec.removedFrame = frame
  composer.removeScene("sceneA")
  L.log("D immediately after composer.removeScene: finalize so far", rec.finalize)
end)
wait(1500, function()
  report(_G.S1.sceneRec)
end)
-- E: aggregate leak: 30 objects removed via parent vs 30 via explicit removeSelf; Lua heap after full GC
wait(50, function()
  local function cycle(indirect)
    collectgarbage("collect"); collectgarbage("collect")
    local before = collectgarbage("count")
    local weak = setmetatable({}, { __mode = "v" })
    local parent = display.newGroup()
    for i = 1, 30 do
      local o = newSpine(parent)
      weak[i] = rawget(o, "_skeleton")
      if not indirect then o:removeSelf() end
    end
    display.remove(parent)
    return before, weak
  end
  local b1, w1 = cycle(false)
  _G.S1.E = { b1 = b1, w1 = w1 }
  timer.performWithDelay(1200, function()
    collectgarbage("collect"); collectgarbage("collect")
    local n1 = 0; for i = 1, 30 do if w1[i] then n1 = n1 + 1 end end
    local d1 = collectgarbage("count") - b1
    local b2, w2 = cycle(true)
    timer.performWithDelay(1200, function()
      collectgarbage("collect"); collectgarbage("collect")
      local n2 = 0; for i = 1, 30 do if w2[i] then n2 = n2 + 1 end end
      local d2 = collectgarbage("count") - b2
      L.log(("E explicit removeSelf x30: skeleton userdata alive %d/30, Lua heap delta %.1f KB"):format(n1, d1))
      L.log(("E display.remove(parent) x30: skeleton userdata alive %d/30, Lua heap delta %.1f KB"):format(n2, d2))
      L.check("leak", #leaked == 0 and n1 == 0 and n2 == 0, "leaked cases", table.concat(leaked, ","), "explicit removal alive", n1 .. "/30", "parent removal alive", n2 .. "/30")
      L.finish(0)
    end)
  end)
end)
run()
