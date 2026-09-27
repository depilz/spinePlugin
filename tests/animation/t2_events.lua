-- T2: listener event sequence + payload shape (incl. per-key event values vs EventData defaults),
-- event.target type, create(listener) vs setListener.
-- t2_events.lua payload|target: checks the per-key payload (animation-4) or event.target (animation-5).
local fx = require("realdata_fixture")
local W = arg[0]:match("^(.*)/")
local C = dofile(W .. "/../check.lua")
local mode = arg[1]
local data = fx.loadData("spineboy/spineboy.atlas", W .. "/assets/" .. os.getenv("SPINE_RUNTIME") .. "/spineboy-events.json")

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
s = fx.createPlugin(data, function(ev) log[#log + 1] = dump(ev) end)

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
print("target is SpineSkeleton userdata (mt has only __gc):", getmetatable(target) and getmetatable(target).__gc ~= nil, getmetatable(target) and getmetatable(target).__index)
print("target.x ->", pcall(function() return target.x end))
print("target:setAnimation ->", pcall(function() return target:setAnimation(1, "idle", true) end))
if mode == "target" then C.expect(target == s, "event.target is not the spine object (animation-5)") end

print("-- per-key event values: walk key0 has int=42 float=2.5 string='per-key' volume=0.3 balance=-0.5; data defaults int=1 float=0.5 string='data-default' volume=0.8 balance=0.1")
local evs = {}
s:setListener(function(ev) if ev.name == "footstep" then evs[#evs + 1] = ev end end)
s:setAnimation(1, "walk", true)
s.tracks[1].mixDuration = 0
for i = 1, 12 do s:updateState(100) end
local perKey = 0
for i, ev in ipairs(evs) do
  print(i, "int", ev.int, "float", ev.float, "string", ev.string, "audioPath", ev.audioPath, "volume", ev.volume, "balance", ev.balance, "time", ev.time, "phase", ev.phase, "looping", ev.looping)
  if ev.int == 42 and ev.float == 2.5 and ev.string == "per-key" then perKey = perKey + 1 end
end
if mode == "payload" then C.expect(perKey > 0, "no footstep event carries key 0's values, only EventData defaults (animation-4)") end
print("done")
C.done()
