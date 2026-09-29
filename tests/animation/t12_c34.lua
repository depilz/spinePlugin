-- T12: the 4.2.120 behaviour changes the plugin ships (CHANGELOG, plugin.spine42), one mode each; the same on 4.3.
-- t12_c34.lua gravity|queued|paused|dragon
--   gravity  translation physics gravity pulls a bone down on screen (Bone::setYDown, upstream eca4b9e4c)
--   queued   an entry queued behind a zero-length one starts at its delay; entry.delay is never negative (ec3231f86)
--   paused   with timeScale 0, a zero-mix setAnimation ends the old entry at once (23233222f)
--   dragon   a sequence slot shows its setup frame (-1) while its animation mixes out and after (90f6bfe49)
local spine = require("plugin.spine")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local mode = arg[1]

-- load(name) -> the skeleton data of <name>/<name>.json with its atlas
local function load(name)
  return spine.loadSkeletonData(name .. "/" .. name .. ".json", spine.loadAtlas(name .. "/" .. name .. ".atlas"))
end

if mode == "gravity" then
  -- rain-blue: x/y physics, strength 0, gravity 70; the empty track keeps updateState stepping the skeleton clock
  local s = spine.create(load("cloud-pot"))
  local rain
  for _, bone in ipairs(s.bones) do if bone.name == "rain-blue" then rain = bone end end
  s:setEmptyAnimation(1, 0)
  local ys = {}
  for i = 1, 30 do s:updateState(1000 / 60); s:draw(); ys[i] = rain.worldY end
  print(("rain-blue worldY frame 1 %.2f, frame 30 %.2f"):format(ys[1], ys[30]))
  C.expect(ys[30] > ys[1] + 100, "translation gravity does not pull rain-blue down on screen (worldY must grow)")
elseif mode == "queued" then
  -- spineboy 'aim' is 0 ms long: with a 200 ms mix, delay 0 used to become -200 and walk started 200 ms in
  local s = spine.create(load("spineboy"))
  s:setDefaultMix(200)
  s:setAnimation(1, "aim", false)
  local walk = s:addAnimation(1, "walk", true, 0)
  print("queued walk delay", walk.delay)
  C.expect(walk.delay >= 0, "entry.delay is negative: " .. walk.delay)
  for i = 1, 3 do
    s:updateState(10)
    print(("  after %d ms: current %s, walk trackTime %.2f, delay %.2f"):format(i * 10, s:getCurrentAnimation(1), walk.trackTime, walk.delay))
  end
  C.expect(s:getCurrentAnimation(1) == "walk", "walk is not current 30 ms after the zero-length aim")
  C.expect(walk.trackTime <= 30 + 1e-3, ("walk skipped time: trackTime %.2f ms after 30 ms"):format(walk.trackTime))
elseif mode == "paused" then
  local clock, paused, phases = 0, false, {}
  local s = spine.create(load("spineboy"), function(ev)
    if ev.name ~= "spine" then return end
    print(("  %-11s %-5s t=%dms%s"):format(ev.phase, ev.animation, clock, paused and " (paused)" or ""))
    if ev.animation == "walk" and paused then phases[ev.phase] = clock end
  end)
  local function run(ms) for i = 1, ms / 10 do s:updateState(10); clock = clock + 10 end end
  s:setAnimation(1, "walk", true)
  run(50)
  s.timeScale = 0
  paused = true
  s:setAnimation(1, "run", true).mixDuration = 0
  run(30)
  paused = false
  s.timeScale = 1
  run(30)
  C.expect(phases.ended ~= nil, "walk 'ended' did not fire while paused after the zero-mix setAnimation")
  C.expect(phases.disposed ~= nil, "walk 'disposed' did not fire while paused after the zero-mix setAnimation")
elseif mode == "dragon" then
  -- flying keys the left-wing slot's sequence; the 4.3 line reads its sequence-timeline export (dragon-ess) here
  local s = spine.create(load("dragon"))
  local function steps(ms, n, label)
    local seen = {}
    for i = 1, n do s:updateState(ms); seen[i] = __native.sequenceIndex(s, "left-wing") end
    print(label, table.concat(seen, ","))
    return seen
  end
  local function all(seen, v) for _, x in ipairs(seen) do if x ~= v then return false end end return true end
  s:setAnimation(1, "flying", true)
  local loop = steps(70, 12, "flying loop, 70 ms steps        ")
  s:setEmptyAnimation(1, 500)
  local mixOut = steps(50, 12, "setEmptyAnimation(1, 500), 50 ms")
  local after = steps(50, 6, "after the mix-out, 50 ms        ")
  C.expect(not all(loop, -1), "the flying loop never sets a sequence frame on left-wing")
  C.expect(all(mixOut, -1), "left-wing does not show the setup frame (-1) through the mix-out")
  C.expect(all(after, -1), "left-wing does not stay on the setup frame (-1) after the mix-out")
else
  error("usage: t12_c34.lua gravity|queued|paused|dragon")
end
print("done")
C.done()
