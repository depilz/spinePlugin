-- S6: Corona/tests/Performance.lua workload (150 raptors @0.3) timed in the real Simulator. Mac Simulator, not device.
-- CHECK meshes: <= 460 real children for the 150 raptors (batched). CHECK alloc: <= 1000 KB of Lua allocation per
-- frame with the collector stopped.
-- Argument (optional, words in any order): a plugin require name to load instead of build.settings' (tools/perf loads
-- plugin.spine for the 1.x baselines, whose unbatched meshes fail CHECK meshes by design), and "sample": at each
-- "MARK <name>" line (created, warm, end) the scenario then waits for <results dir>/<name>.ack, which tools/perf
-- writes once it has sampled the Simulator's footprint.
local L = require("simlib")
L.watchdogMs = 240000
L.open("s6_perf")
L.expect("meshes", "alloc")
L.log("(Mac Simulator, not device)")
local plugin, sample
for w in L.arg:gmatch("%S+") do if w == "sample" then sample = true else plugin = w end end
local spine = L.loadPlugin(plugin)
local phase = "warm"
local ack -- sample mode: the ack file the "hold" phase waits on before it resumes ackPhase
local ackPhase
local function mark(name, nextPhase)
  L.log("MARK", name, ("lua %.0f KB"):format(collectgarbage("count")))
  phase = nextPhase
  if sample then ack, ackPhase, phase = L.dir .. "/" .. name .. ".ack", nextPhase, "hold" end
end
math.randomseed(1)
local atlas = spine.loadAtlas("spines/raptor/raptor.atlas")
local data = spine.loadSkeletonData("spines/raptor/raptor.skel", atlas, 0.3)
local parent = display.newGroup()
local probe = spine.create(data)
local animations = probe:getAnimations()
probe:removeSelf()
local objs = {}
local tc = system.getTimer()
for i = 1, 150 do
  local o = spine.create(data)
  o.x, o.y = math.random(0, display.actualContentWidth), math.random(0, display.actualContentHeight)
  parent:insert(o)
  o:draw()
  o:setAnimation(1, animations[1], true)
  objs[i] = o
end
L.log(("create x150: %.1f ms, animation '%s'"):format(system.getTimer() - tc, animations[1]))
mark("created", "warm")
local gidx = getmetatable(display.newGroup()).__index
local function meshCount()
  local n = 0
  for i = 1, #objs do n = n + gidx(objs[i], "numChildren") end
  return n
end
local DT = 1000 / 60
local WARM, MEASURE, GCPROBE = 30, 300, 60
local frame, work, gcDelta, intervals = 0, {}, {}, {}
local lastT
local function step()
  for i = 1, #objs do local o = objs[i]; o:updateState(DT); o:draw() end
end
Runtime:addEventListener("enterFrame", function()
  if phase == "hold" then
    local f = io.open(ack)
    if f then f:close(); phase = ackPhase end
    return
  end
  if phase == "finish" then return L.finish(0) end
  local now = system.getTimer()
  frame = frame + 1
  if phase == "warm" then
    step()
    if frame >= WARM then
      frame = 0; L.log("meshes (real Solar2D children) after warm-up:", meshCount())
      mark("warm", "measure")
    end
  elseif phase == "measure" then
    if lastT then intervals[#intervals + 1] = now - lastT end
    lastT = now
    local c0 = collectgarbage("count")
    local t0 = system.getTimer()
    step()
    local t1 = system.getTimer()
    work[#work + 1] = t1 - t0
    gcDelta[#gcDelta + 1] = collectgarbage("count") - c0
    if frame >= MEASURE then phase = "gcprobe"; frame = 0; collectgarbage("collect") end
  elseif phase == "gcprobe" then
    -- allocation per frame with the collector stopped (pure garbage production of updateState+draw)
    collectgarbage("stop")
    local c0 = collectgarbage("count")
    step()
    gcDelta.stopped = (gcDelta.stopped or 0) + (collectgarbage("count") - c0)
    collectgarbage("restart"); collectgarbage("collect")
    if frame >= GCPROBE then
      phase = "done"
      local function stats(t)
        local s = {}; local sum = 0
        for i = 1, #t do s[i] = t[i]; sum = sum + t[i] end
        table.sort(s)
        return sum / #s, s[math.max(1, math.ceil(#s * 0.95))], s[math.ceil(#s * 0.5)], s[#s]
      end
      local avg, p95, p50, mx = stats(work)
      L.log(("updateState+draw x150 per frame over %d frames: avg %.2f ms, p50 %.2f, p95 %.2f, max %.2f"):format(#work, avg, p50, p95, mx))
      local gavg = 0; for i = 1, #gcDelta do gavg = gavg + gcDelta[i] end; gavg = gavg / #gcDelta
      L.log(("collectgarbage('count') delta per measured frame (collector running): mean %.1f KB"):format(gavg))
      local alloc = gcDelta.stopped / GCPROBE
      L.log(("Lua allocation per frame with collector stopped (mean of %d frames): %.1f KB"):format(GCPROBE, alloc))
      local iavg, ip95 = stats(intervals)
      L.log(("enterFrame interval: avg %.1f ms, p95 %.1f ms (Simulator window throttled; not a render-cost measure)"):format(iavg, ip95))
      local meshes = meshCount()
      L.log("meshes at end:", meshes)
      L.check("meshes", meshes <= 460, meshes)
      L.check("alloc", alloc <= 1000, ("%.1f KB"):format(alloc))
      mark("end", "finish")
    end
  end
end)
