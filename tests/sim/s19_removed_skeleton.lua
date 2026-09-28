-- S19: Lua calls on a skeleton removed with obj:removeSelf(), in two windows of the removal frame. Window a is the
-- handler that removed it, right after removeSelf. Window b is a later handler in the same frame: the finalize listener
-- of a sentinel removed just before the skeleton, which Solar2D finalizes after the skeleton's finalize and
-- RestoreTable (it finalizes the frame's orphans last-removed first), before the next frame's dispose hook.
-- "removed": numChildren and findAnimation in both windows and after the hook, with a live findAnimation control.
-- "late": one check per late-call probe and window. Methods named "cached" were read from the object before removal.
-- "late" also checks the skeleton's own finalize listener, which calls e.target:removeEventListener.
-- Solar2D's own methods cached before removal abort the Simulator (s9) and are not probed.
local L = require("simlib")
L.watchdogMs = 20000
local MODE = L.arg
local DEAD = "Skeleton belongs to a removed skeleton"

-- raises(want, fn, ...): fn raises an error containing want
local function raises(want, fn, ...)
  local ok, err = pcall(fn, ...)
  return not ok and tostring(err):find(want, 1, true) ~= nil, ok and "no error" or tostring(err)
end
-- returns(want, fn, ...): fn runs and returns want
local function returns(want, fn, ...)
  local ok, got = pcall(fn, ...)
  return ok and got == want, (ok and "returned " or "raised ") .. tostring(got)
end
-- nilCall(name): obj:name() finds no method and raises Lua's generic nil-call error
local function nilCall(name)
  return function(obj)
    local ok, err = pcall(function() return obj[name](obj) end)
    err = tostring(err)
    return not ok and err:find("attempt to call", 1, true) ~= nil and err:find("a nil value", 1, true) ~= nil,
      ok and "no error" or err
  end
end
local function read(key) return function(obj) return returns(nil, function() return obj[key] end) end end
local function same(id, probe) return { id, a = probe, b = probe } end

local cached, bone, heard = {}, nil, 0
local function unheard() end -- added before removal; window a removes it
local function onFinal() end -- added before removal; the skeleton's finalize listener removes it
local finalized -- the ok, detail of that removal; nil until the finalize listener runs
local function runs(name, want, ...)
  local args = { ... }
  return function(obj) return returns(want, cached[name], obj, unpack(args)) end
end
local function dead(name, ...)
  local args = { ... }
  return function(obj) return raises(DEAD, cached[name], obj, unpack(args)) end
end

-- the late-call probes, in call order: { id, a = probe, b = probe }; a probe returns ok, detail
local LATE = {
  same("setAnimation", nilCall("setAnimation")),
  { "setAnimation cached", a = runs("setAnimation", nil, 1, "run", true), b = dead("setAnimation", 1, "run", true) },
  same("updateState", nilCall("updateState")),
  { "updateState cached", a = runs("updateState", nil, 16), b = dead("updateState", 16) },
  same("draw", nilCall("draw")),
  { "draw cached", a = runs("draw", nil), b = dead("draw") },
  same("findAnimation", nilCall("findAnimation")),
  { "findAnimation cached", a = runs("findAnimation", true, "walk"), b = dead("findAnimation", "walk") },
  same("toFront", nilCall("toFront")),
  same("insert", nilCall("insert")),
  same("numChildren", read("numChildren")),
  same("[1]", read(1)),
  same("x read", read("x")),
  same("parent read", read("parent")),
  { "x alpha write",
    -- a: forwarded to the display group, nothing lands in the table; b: a plain table write
    a = function(obj)
      local ok, err = pcall(function() obj.x, obj.alpha = 12, 0.5 end)
      return ok and rawget(obj, "x") == nil and rawget(obj, "alpha") == nil,
        ok and ("raw x %s, raw alpha %s"):format(tostring(rawget(obj, "x")), tostring(rawget(obj, "alpha"))) or tostring(err)
    end,
    b = function(obj)
      local ok, err = pcall(function() obj.x, obj.alpha = 12, 0.5 end)
      return ok and rawget(obj, "x") == 12 and rawget(obj, "alpha") == 0.5,
        ok and ("raw x %s, raw alpha %s"):format(tostring(rawget(obj, "x")), tostring(rawget(obj, "alpha"))) or tostring(err)
    end },
  { "addEventListener",
    a = function(obj)
      return returns(true, function() return obj:addEventListener("s19added", function() end) end)
    end,
    b = nilCall("addEventListener") },
  { "dispatchEvent", -- to the listener newSkeleton added before removal
    a = function(obj)
      local before = heard
      local ok, err = pcall(function() obj:dispatchEvent({ name = "s19probe" }) end)
      return ok and heard == before + 1, ok and ("listener calls %d"):format(heard - before) or tostring(err)
    end,
    b = nilCall("dispatchEvent") },
  { "removeEventListener",
    a = function(obj)
      return returns(true, function() return obj:removeEventListener("s19unheard", unheard) end)
    end,
    b = nilCall("removeEventListener") },
  { "bone",
    a = function() return returns("number", function() return type(bone.x) end) end,
    b = function() return raises("Bone belongs to a removed skeleton", function() return bone.x end) end },
  same("removeSelf", nilCall("removeSelf")),
  { "removeSelf cached", a = runs("removeSelf", nil), b = dead("removeSelf") },
  same("display.remove", function(obj)
    local ok, err = pcall(display.remove, obj)
    return ok, ok and "no error" or tostring(err)
  end),
}
-- the removed-skeleton checks of "removed", per window ("hook": a later frame, after the dispose hook freed it)
local REMOVED = {
  { "numChildren", a = read("numChildren"), b = read("numChildren"), hook = read("numChildren") },
  { "findAnimation cached", a = runs("findAnimation", true, "walk"), b = dead("findAnimation", "walk"),
    hook = dead("findAnimation", "walk") },
  { "findAnimation method", a = nilCall("findAnimation"), b = nilCall("findAnimation"), hook = nilCall("findAnimation") },
}

L.open("s19_removed_skeleton_" .. MODE)
if MODE == "late" then
  local ids = { "window", "finalize removeEventListener" }
  for _, w in ipairs({ "a", "b" }) do for _, p in ipairs(LATE) do ids[#ids + 1] = w .. " " .. p[1] end end
  L.expect(unpack(ids))
else
  L.expect("live findAnimation", "window", "numChildren", "findAnimation cached", "findAnimation method")
end
local spine = L.loadPlugin()
local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.3)

-- runProbe(probe, obj): ok, detail; a probe that raises by itself is a failed check, not an unhandled error
local function runProbe(probe, obj)
  local ok, pass, detail = pcall(probe, obj)
  if not ok then return false, "probe raised " .. tostring(pass) end
  return pass, detail
end

-- removeInWindows(obj, onA, onB): removes obj with obj:removeSelf(); onA(obj) runs right after it, onB(obj) in window b.
-- The "window" check holds when a keeps the metatable and b sees it stripped with _skeleton still set, in the same frame.
local function removeInWindows(obj, onA, onB)
  local frame, windowA = L.frames, getmetatable(obj) ~= nil
  local sentinel = display.newRect(0, 0, 4, 4)
  sentinel:addEventListener("finalize", function()
    local metatable, skeleton = getmetatable(obj), type(rawget(obj, "_skeleton"))
    L.check("window", windowA and metatable == nil and skeleton == "userdata" and L.frames == frame,
      ("a: metatable %s; b: metatable %s, _skeleton %s, frames since removal %d"):format(
        tostring(windowA), tostring(metatable), skeleton, L.frames - frame))
    onB(obj)
  end)
  sentinel:removeSelf()
  obj:removeSelf()
  windowA = windowA and getmetatable(obj) ~= nil
  onA(obj)
end

local function newSkeleton()
  local obj = spine.create(data)
  obj.x, obj.y = 200, 400
  obj:setAnimation(1, "walk", true); obj:updateState(16); obj:draw()
  for _, name in ipairs({ "setAnimation", "updateState", "draw", "findAnimation", "removeSelf" }) do cached[name] = obj[name] end
  bone = obj.bones[1]
  obj:addEventListener("s19probe", function() heard = heard + 1 end)
  obj:addEventListener("s19unheard", unheard)
  obj:addEventListener("s19final", onFinal)
  obj:addEventListener("finalize", function(e)
    finalized = { returns(true, function() return e.target:removeEventListener("s19final", onFinal) end) }
  end)
  return obj
end

local function finishSoon() timer.performWithDelay(300, function() L.log("engine still alive"); L.finish(0) end) end

timer.performWithDelay(50, function()
  local obj = newSkeleton()
  if MODE == "late" then
    local function probeAll(w)
      return function(o) for _, p in ipairs(LATE) do L.check(w .. " " .. p[1], runProbe(p[w], o)) end end
    end
    removeInWindows(obj, probeAll("a"), function(o)
      probeAll("b")(o)
      -- the skeleton was removed after the sentinel, so its finalize listener has run before window b
      L.check("finalize removeEventListener", unpack(finalized or { false, "finalize listener did not run" }))
      finishSoon()
    end)
    return
  end
  local found, missing = obj:findAnimation("walk"), obj:findAnimation("nope")
  L.check("live findAnimation", found == true and missing == false,
    ("walk %s, nope %s"):format(tostring(found), tostring(missing)))
  local results = {} -- per check: pass and detail of each window
  local function probeWindow(w)
    return function(o)
      for _, p in ipairs(REMOVED) do
        local r = results[p[1]] or { pass = true, detail = {} }
        local pass, detail = runProbe(p[w], o)
        r.pass = r.pass and pass
        r.detail[#r.detail + 1] = w .. ": " .. tostring(detail)
        results[p[1]] = r
      end
    end
  end
  removeInWindows(obj, probeWindow("a"), probeWindow("b"))
  timer.performWithDelay(200, function()
    probeWindow("hook")(obj)
    for _, p in ipairs(REMOVED) do
      local r = results[p[1]]
      L.check(p[1], r.pass and #r.detail == 3, table.concat(r.detail, "; "))
    end
    finishSoon()
  end)
end)
