-- Many skeletons per frame (mirrors Corona/tests/Performance.lua: 150 raptors @0.3, animations[1] looping).
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock = C.mock
local name = arg and arg[1] or "raptor"
local N = tonumber(arg and arg[2]) or 150
local data = C.data(name, 0.3)
local objs = {}
for i = 1, N do
  local o = C.spine.create(data)
  o:setAnimation(1, o:getAnimations()[1], true)
  o:updateState(i * 7 % 1000) -- de-synchronise
  objs[i] = o
end
local function frame()
  for i = 1, N do local o = objs[i]; o:updateState(1000 / 60); o:draw() end
end
for f = 1, 30 do frame() end
-- garbage per frame
collectgarbage("collect"); collectgarbage("stop")
local k0 = collectgarbage("count")
for f = 1, 20 do frame() end
local kbPerFrame = (collectgarbage("count") - k0) / 20
collectgarbage("restart"); collectgarbage("collect")
-- time per frame with the default incremental GC running
local F = 300
local t0 = os.clock()
for f = 1, F do frame() end
local t = (os.clock() - t0) / F
-- time per frame with GC stopped (upper bound on the GC share)
collectgarbage("collect"); collectgarbage("stop")
local t1 = os.clock()
for f = 1, 60 do frame() end
local tNoGC = (os.clock() - t1) / 60
collectgarbage("restart")
mock.resetStats(); for f = 1, 60 do frame() end
print(("%s x%d: Lua garbage %.0f KB/frame | CPU %.2f ms/frame (GC on), %.2f ms/frame (GC off) | Solar2D meshes %d, path:update calls/frame %d, newMesh/frame %.1f, removeSelf/frame %.1f")
  :format(name, N, kbPerFrame, t * 1000, tNoGC * 1000, mock.live.meshes, (mock.stats.pathUpdate or 0) / 60, (mock.stats.newMesh or 0) / 60, (mock.stats.meshRemoveSelf or 0) / 60))
-- batching: no two consecutive drawable, non-injection commands may share texture, blend and colors
local unmerged, prev = 0, nil
for _, c in ipairs(C.fx.expected(objs[1])) do
  if c.numIndices >= 3 then
    if prev and c.injectionSlot < 0 and prev.injectionSlot < 0 and c.tex == prev.tex and c.blend == prev.blend
      and c.color == prev.color and c.dark == prev.dark then unmerged = unmerged + 1 end
    prev = c
  end
end
print(("%s: %d consecutive commands left unbatched"):format(name, unmerged))
C.expect(unmerged == 0, "commands not batched (render-1)")
C.done()
