-- The stub's display-object EventDispatcher against Solar2D's platform/resources/init.lua:74-273. Each mode runs on a
-- plain display group and on a spine object, whose dispatcher keys reach the group's through the plugin's __index.
-- order: function listeners before table listeners, each in registration order; one event table, target untouched.
-- clone: a dispatch runs over a copy of the list; a listener removed mid-dispatch is skipped, one added is not run.
-- missing: a table listener without the event's method is skipped. return: dispatchEvent returns the listeners'
-- results or-ed, false when none. has: hasEventListener and respondsToEvent. remove: removeEventListener removes the
-- first matching registration only. finalize: the stub's frame-end "finalize" uses the same dispatch.
-- forms: explicit-self and missing-self calls, nil and non-string event names, a nil listener and malformed events.
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1]
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)

local function check(obj, label)
  local log = {}
  local function fn(tag, ret) return function(e) log[#log + 1] = { tag, e }; return ret end end
  local function tbl(tag, ret) return { ev = function(self, e) log[#log + 1] = { tag, e }; return ret end } end
  local function tags() local t = {} for i, v in ipairs(log) do t[i] = v[1] end return table.concat(t, ",") end
  local function expect(want) local got = tags(); log = {}; assert(got == want, label .. ": ran " .. got .. ", expected " .. want) end

  if mode == "order" then
    local a, b = tbl("A"), tbl("B")
    obj:addEventListener("ev", a); obj:addEventListener("ev", fn("f1")); obj:addEventListener("ev", b)
    obj:addEventListener("ev", fn("f2"))
    local event = { name = "ev" }
    obj:dispatchEvent(event)
    for _, v in ipairs(log) do assert(rawequal(v[2], event), label .. ": a listener got another event table") end
    assert(rawget(event, "target") == nil, label .. ": dispatchEvent set event.target")
    expect("f1,f2,A,B")
  elseif mode == "clone" then
    local f1, f2, f3
    f3 = fn("f3")
    f1 = function(e) log[#log + 1] = { "f1" }; obj:removeEventListener("ev", f1); obj:addEventListener("ev", f3) end
    f2 = fn("f2")
    local f4 = function(e) log[#log + 1] = { "f4" }; obj:removeEventListener("ev", f2) end
    obj:addEventListener("ev", f1); obj:addEventListener("ev", f2); obj:addEventListener("ev", f4)
    obj:dispatchEvent({ name = "ev" })
    expect("f1,f2,f4")            -- f1 removing itself does not skip f2; f3 added mid-dispatch waits
    local g1 = function(e) log[#log + 1] = { "g1" }; obj:removeEventListener("ev", f2) end
    obj:removeEventListener("ev", f4); obj:removeEventListener("ev", f3)
    obj:addEventListener("ev", g1); obj:addEventListener("ev", f2)
    obj:dispatchEvent({ name = "ev" })
    expect("g1")                  -- f2, removed by g1 before its turn, is skipped
  elseif mode == "missing" then
    obj:addEventListener("ev", { other = function() error("wrong method called") end })
    obj:addEventListener("ev", tbl("B"))
    local ok, err = pcall(obj.dispatchEvent, obj, { name = "ev" })
    assert(ok, label .. ": a table listener without the method raised: " .. tostring(err))
    expect("B")
  elseif mode == "return" then
    local r = obj:dispatchEvent({ name = "ev" })
    assert(r == false, label .. ": no listener returned " .. tostring(r))
    obj:addEventListener("ev", fn("f1")); obj:addEventListener("ev", tbl("A"))
    r = obj:dispatchEvent({ name = "ev" })
    assert(r == false, label .. ": nil-returning listeners returned " .. tostring(r))
    obj:addEventListener("ev", fn("f2", true)); obj:addEventListener("ev", tbl("B"))
    log = {}
    r = obj:dispatchEvent({ name = "ev" })
    assert(r == true, label .. ": a true-returning listener returned " .. tostring(r))
    expect("f1,f2,A,B")           -- a true result does not stop the dispatch
  elseif mode == "has" then
    local f, t = fn("f"), tbl("t")
    assert(obj:hasEventListener("ev", f) == false and not obj:respondsToEvent("ev"), label .. ": listener before add")
    obj:addEventListener("ev", f); obj:addEventListener("ev", t)
    assert(obj:hasEventListener("ev", f) == true and obj:hasEventListener("ev", t) == true, label .. ": hasEventListener")
    assert(obj:hasEventListener("ev", fn("other")) == false, label .. ": hasEventListener on an unregistered function")
    assert(obj:respondsToEvent("ev"), label .. ": respondsToEvent")
    obj:removeEventListener("ev", f)
    assert(obj:hasEventListener("ev", f) == false and obj:respondsToEvent("ev"), label .. ": after one removal")
    obj:removeEventListener("ev", t)
    assert(not obj:respondsToEvent("ev"), label .. ": respondsToEvent after every removal")
  elseif mode == "remove" then
    local f, g = fn("f"), fn("g")
    assert(obj:addEventListener("ev", f) == true and obj:addEventListener("ev", g) == true
      and obj:addEventListener("ev", f) == true, label .. ": add returns true")
    obj:dispatchEvent({ name = "ev" })
    expect("f,g,f")
    assert(obj:removeEventListener("ev", f) == true, label .. ": first removal")
    obj:dispatchEvent({ name = "ev" })
    expect("g,f")                 -- only the first f went; the one after g stays
    assert(obj:removeEventListener("ev", fn("absent")) == nil, label .. ": removing an absent listener")
  elseif mode == "forms" then
    local f = fn("f")
    assert(obj.addEventListener(obj, "ev", f) == true, label .. ": a dot call with self")
    obj:dispatchEvent({ name = "ev" })
    expect("f")
    S.raises("method 'respondsToEvent' (a nil value)", obj.addEventListener, "ev", f)
    S.raises("table index is nil", obj.addEventListener, obj, nil, f)
    assert(obj:addEventListener(42, fn("n")) == true, label .. ": a number event name")
    obj:dispatchEvent({ name = 42 })
    expect("n")
    S.raises("addEventListener: listener cannot be nil: nil", obj.addEventListener, obj, "ev", nil)
    assert(obj:dispatchEvent({}) == false and obj:dispatchEvent("ev") == false, label .. ": an event without a name")
    expect("")
    S.raises("attempt to index local 'event' (a nil value)", obj.dispatchEvent, obj, nil)
    S.raises("attempt to index local 'event' (a number value)", obj.dispatchEvent, obj, 42)
    S.raises("attempt to index local 'event' (a boolean value)", obj.dispatchEvent, obj, true)
  elseif mode == "finalize" then
    local events = {}
    local a = { finalize = function(self, e) log[#log + 1] = { "A" }; events[#events + 1] = e end }
    obj:addEventListener("finalize", a)
    obj:addEventListener("finalize", {})
    obj:addEventListener("finalize", function(e) log[#log + 1] = { "f" }; events[#events + 1] = e end)
    obj:removeSelf()
    S.endFrame()
    expect("f,A")
    assert(rawequal(events[1], events[2]) and rawequal(events[1].target, obj), label .. ": finalize event or target")
    return
  else
    error("unknown mode " .. tostring(mode))
  end
  obj:removeSelf()
end

check(display.newGroup(), "group")
check(spine.create(data), "spine")
S.frame()
S.gcfull()
print("survived")
