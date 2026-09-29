-- T2: listener event sequence + payload shape (the L13 custom event: per-key values, time in ms),
-- event.target type, create(listener) vs setListener.
-- t2_events.lua payload|target: checks the custom events' L13 payload (animation-4) or event.target (animation-5).
local spine = require("plugin.spine")
local W = arg[0]:match("^(.*)/")
local C = dofile(W .. "/../check.lua")
local mode = arg[1]
local data = spine.loadSkeletonData(W .. "/assets/" .. os.getenv("SPINE_RUNTIME") .. "/spineboy-events.json", spine.loadAtlas("spineboy/spineboy.atlas"))

local function dump(ev)
  local keys = {}
  for k in pairs(ev) do keys[#keys + 1] = k end
  table.sort(keys)
  local parts = {}
  for _, k in ipairs(keys) do
    local v = ev[k]
    if k == "target" then v = type(v) .. (type(v) == "userdata" and ("/mt=" .. tostring(getmetatable(v) and getmetatable(v).__gc ~= nil)) or "") end
    parts[#parts + 1] = k .. "=" .. tostring(v)
  end
  return table.concat(parts, " ")
end

local log = {}
local s
s = spine.create(data, function(ev) log[#log + 1] = dump(ev) end)

print("-- walk (looping) for 1.1s, then setAnimation run with default mix 200ms, run 0.5s")
s:setDefaultMix(200)
s:setAnimation(1, "walk", true)
for i = 1, 11 do s:updateState(100) end
s:setAnimation(1, "run", true)
for i = 1, 5 do s:updateState(100) end
for i, l in ipairs(log) do print(i, l) end

print("-- event.target usability")
local target
s:setListener(function(ev) target = ev.target end)
s:setAnimation(2, "idle", true) -- fires 'began' synchronously
print("type(target)", type(target), "target == s", target == s, "target == s._skeleton", target == rawget(s, "_skeleton"))
print("target metatable __gc, __index:", getmetatable(target) and getmetatable(target).__gc ~= nil, getmetatable(target) and getmetatable(target).__index)
print("target.x ->", pcall(function() return target.x end))
print("target:setAnimation ->", pcall(function() return target:setAnimation(1, "idle", true) end))
if mode == "target" then C.expect(target == s, "event.target is not the spine object (animation-5)") end

print("-- per-key event values: walk key0 has int=42 float=2.5 string='per-key' volume=0.3 balance=-0.5; data defaults int=1 float=0.5 string='data-default' volume=0.8 balance=0.1")
local evs = {}
s:setListener(function(ev) if ev.phase == "event" then evs[#evs + 1] = ev end end)
s:setAnimation(1, "walk", true)
s.tracks[1].mixDuration = 0
for i = 1, 12 do s:updateState(100) end
for i, ev in ipairs(evs) do print(i, dump(ev)) end
-- A key without volume/balance: the 4.2 JSON reader gives 1/0, 4.3's the EventData's (runtime readers, both upstream).
local unkeyedVolume = os.getenv("SPINE_RUNTIME") == "4.2" and { 1, 0 } or { 0.8, 0.1 }
local expected = {
  { int = 42, float = 2.5, string = "per-key", volume = 0.3, balance = -0.5, time = 0 },
  { int = 1, float = 0.5, string = "data-default", volume = unkeyedVolume[1], balance = unkeyedVolume[2], time = 500 },
}
local function near(a, b) return type(a) == "number" and math.abs(a - b) < 1e-6 end
local function matches(ev, want)
  return ev.name == "spine" and ev.event == "footstep" and ev.animation == "walk" and ev.trackIndex == 1
    and ev.target == s and ev.looping == nil and ev.audioPath == "sfx/step.ogg" and ev.int == want.int
    and near(ev.float, want.float) and ev.string == want.string and near(ev.volume, want.volume)
    and near(ev.balance, want.balance) and near(ev.time, want.time)
end
if mode == "payload" then
  C.expect(#evs >= 2, ("%d custom events from walk, expected its two keys"):format(#evs))
  for i, want in ipairs(expected) do
    C.expect(evs[i] and matches(evs[i], want), ("custom event %d is not key %d's L13 payload (animation-4)"):format(i, i - 1))
  end
end
print("done")
C.done()
