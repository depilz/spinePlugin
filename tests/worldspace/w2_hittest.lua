-- W2: skeleton:hitTest(x, y[, listener]) in content coordinates, one mode per scenarios row: geometry against the
-- SkeletonBounds oracle, draw-order walk and stop, skin and applied-pose attachments, no pose refresh, bad arguments,
-- stale skeletons, and listeners that remove, reskin, change attachments or raise.
local spine = require("plugin.spine")
local S = __stub
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local W = arg[0]:match("^(.*)/")
local mode, how = arg[1], arg[2]
local DEAD = "Skeleton belongs to a removed skeleton"

local function near(a, b) return math.abs(a - b) <= 1e-9 end

local function spineboy()
  return spine.create(spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas")))
end
local function fixture()
  return spine.create(spine.loadSkeletonData(W .. "/assets/" .. os.getenv("SPINE_RUNTIME") .. "/hitboxes.json",
    spine.loadAtlas("spineboy/spineboy.atlas")))
end

-- the slot names the listener sees at (x, y), and hitTest's return
local function walk(obj, x, y, stopAt)
  local seen = {}
  local stopped = obj:hitTest(x, y, function(hit)
    seen[#seen + 1] = hit.slotName
    return #seen == stopAt
  end)
  return table.concat(seen, ","), stopped
end

local modes = {}

function modes.geometry()
  local outer = display.newGroup()
  outer.x, outer.y, outer.xScale, outer.yScale, outer.rotation = 160, 240, 0.8, 0.6, 25
  local inner = display.newGroup()
  outer:insert(inner)
  inner.x, inner.y, inner.xScale, inner.yScale, inner.rotation = 30, -15, 1.4, 0.9, -40
  local obj = spineboy()
  inner:insert(obj)
  obj.x, obj.y, obj.xScale, obj.yScale, obj.rotation = -10, 20, 0.75, 1.2, 15
  obj:setAttachment("head-bb", "head")
  local head
  for _, b in ipairs(obj.bones) do if b.name == "head" then head = b end end
  local hx, hy = obj:localToContent(head.worldX, head.worldY)
  local inside, outside, mismatch = 0, 0, 0
  for i = -40, 40 do for j = -40, 40 do
    local cx, cy = hx + i * 2.5, hy + j * 2.5
    local lx, ly = obj:contentToLocal(cx, cy)
    local oracle = __probe.boundsContains(obj, lx, ly)
    local hit = obj:hitTest(cx, cy)
    if (hit and hit.attachmentName) ~= oracle then
      mismatch = mismatch + 1
      print("mismatch at", cx, cy, hit and hit.attachmentName, oracle)
    end
    if hit then
      inside = inside + 1
      C.expect(hit.slotName == "head-bb" and hit.target == obj and hit.x == cx and hit.y == cy
        and near(hit.localX, lx) and near(hit.localY, ly), "hit table fields differ at " .. cx .. "," .. cy)
    else
      outside = outside + 1
    end
  end end
  print("head grid: inside", inside, "outside", outside, "mismatches", mismatch)
  C.expect(mismatch == 0, mismatch .. " sampled points disagree with SkeletonBounds::containsPoint")
  C.expect(inside > 0 and outside > 0, "the grid did not sample both sides of head-bb")
  obj:removeSelf()
end

-- the Y-down flip puts the A/B/C overlap at (20, -20), not (20, 20)
function modes.order()
  local obj = fixture()
  local seen, stopped = walk(obj, 20, -20)
  print("walk", seen, stopped)
  C.expect(seen == "boxC,boxB,boxA", "listener order is not last drawn first: " .. seen)
  C.expect(stopped == false, "hitTest with a listener that never returned true did not return false")
  local hit = obj:hitTest(20, -20)
  print("top-most", hit.slotName, hit.attachmentName, hit.x, hit.y, hit.localX, hit.localY)
  C.expect(hit.slotName == "boxC" and hit.attachmentName == "boxC" and hit.target == obj, "top-most hit is not boxC")
  C.expect(hit.x == 20 and hit.y == -20 and hit.localX == 20 and hit.localY == -20, "hit coordinates differ")
  local n = 0
  for _ in pairs(hit) do n = n + 1 end
  C.expect(n == 7, "the hit table has " .. n .. " fields")
  C.expect(__probe.boundsContains(obj, 20, -20) == "boxA", "the slot-order oracle did not answer boxA")
  C.expect(obj:hitTest(1000, 1000) == nil, "a far point hit a box")
  obj.isVisible = false
  C.expect(walk(obj, 20, -20) == "boxC,boxB,boxA", "an invisible skeleton changed the walk")
  obj:removeSelf()
end

function modes.reorder()
  local obj = fixture()
  obj:setAnimation(1, "reorder", false)
  obj:updateState(0)
  local seen = walk(obj, 20, -20)
  print("walk", seen)
  C.expect(seen == "boxA,boxB,boxC", "the drawOrder timeline did not change the walk: " .. seen)
  C.expect(obj:hitTest(20, -20).slotName == "boxA", "top-most hit after reorder is not boxA")
  obj:removeSelf()
end

function modes.stop()
  local obj = fixture()
  local seen, stopped = walk(obj, 20, -20, 2)
  print("walk", seen, stopped)
  C.expect(seen == "boxC,boxB" and stopped == true, "returning true did not stop the walk with true: " .. seen)
  obj:removeSelf()
end

function modes.skin()
  local obj = fixture()
  C.expect(obj:hitTest(200, 0) == nil, "boxSkin hit while its skin-only bone is inactive")
  obj:setSkin("extra")
  obj:updateState(0)
  local hit = obj:hitTest(200, 0)
  C.expect(hit and hit.slotName == "boxSkin", "boxSkin not hit once skin extra is set")
  obj:removeSelf()
end

-- 4.2 has no sliders, so slot boxSlid keeps slidPose there
function modes.applied()
  local obj = fixture()
  local want = os.getenv("SPINE_RUNTIME") == "4.3" and "slidApplied" or "slidPose"
  local hit = obj:hitTest(320, 0)
  print("boxSlid", hit and hit.attachmentName, "oracle", __probe.boundsContains(obj, 320, 0))
  C.expect(hit and hit.slotName == "boxSlid" and hit.attachmentName == want, "boxSlid did not answer " .. want)
  C.expect(__probe.boundsContains(obj, 320, 0) == want, "the oracle did not answer " .. want)
  obj:removeSelf()
end

function modes.nopose()
  local obj = fixture()
  local base
  for _, b in ipairs(obj.bones) do if b.name == "base" then base = b end end
  base:setWorldPosition(1000, 1000)
  C.expect(obj:hitTest(20, -20) ~= nil, "hitTest refreshed the pose")
  obj:updateState(0)
  C.expect(obj:hitTest(20, -20) == nil and obj:hitTest(1020, 980) ~= nil, "the moved bone's boxes did not move")
  obj:removeSelf()
end

function modes.badargs()
  local obj = fixture()
  S.raises("bad argument", function() obj:hitTest("x", 1) end)
  S.raises("bad argument", function() obj:hitTest(1) end)
  S.raises("bad argument", function() obj:hitTest(1, 2, "f") end)
  S.raises("bad argument", function() obj:hitTest(1, 2, {}) end)
  C.expect(obj:hitTest(20, -20, nil).slotName == "boxC", "a nil listener is not the listener-less form")
  obj:removeSelf()
end

local function expectStale(fn, obj, where)
  for _, listener in ipairs({ false, true }) do
    local ok, err = pcall(fn, obj, 20, -20, listener and function() end or nil)
    print(where, listener, ok, err)
    C.expect(not ok and tostring(err):find(DEAD, 1, true), where .. ": hitTest did not raise '" .. DEAD .. "'")
  end
end

function modes.stale()
  local obj = fixture()
  local fn = obj.hitTest
  if how == "removed" then
    obj:removeSelf(); S.frame(); S.gcfull()
    expectStale(fn, obj, how)
  elseif how == "window" then
    local inFinalize
    obj:addEventListener("finalize", function() inFinalize = fn(obj, 20, -20) end)
    obj:removeSelf()
    S.endFrame()
    C.expect(inFinalize and inFinalize.slotName == "boxC", "the skeleton's own finalize listener could not hit test")
    expectStale(fn, obj, how)
    S.frame()
    expectStale(fn, obj, how .. " after the next frame")
  elseif how == "finalize" then
    obj:removeSelf(); S.frame()
    local other = display.newGroup()
    local called = false
    other:addEventListener("finalize", function() called = true; expectStale(fn, obj, how) end)
    other:removeSelf(); S.endFrame()
    C.expect(called, "the other object's finalize listener did not run")
  else
    error("unknown stale way " .. tostring(how))
  end
end

function modes.listener()
  local obj = fixture()
  local actions = {
    removeself = function() obj:removeSelf() end,
    skin = function() obj:setSkin("extra") end,
    attachment = function() obj:setAttachment("boxA", nil) end,
  }
  if actions[how] then
    local calls = 0
    local stopped = obj:hitTest(20, -20, function() calls = calls + 1; actions[how]() end)
    print(how, "calls", calls, "returned", stopped)
    C.expect(calls == 1 and stopped == false, how .. ": the walk went on after the listener's change")
    S.frame(); S.gcfull()
    if how ~= "removeself" then obj:removeSelf(); S.frame() end
  elseif how == "error" then
    local ok, err = pcall(obj.hitTest, obj, 20, -20, function() error("listener boom") end)
    print("error", ok, err)
    C.expect(not ok and tostring(err):find("listener boom", 1, true), "the listener's error did not reach the caller")
    obj:draw()
    C.expect(walk(obj, 20, -20) == "boxC,boxB,boxA", "hitTest does not work after a listener error")
    -- a released guard lets the removal dispose the skeleton on the next frame
    obj:removeSelf(); S.frame(); S.frame()
    local ok2, err2 = pcall(__probe.boundsContains, obj, 20, -20)
    print("after removal", ok2, err2)
    C.expect(not ok2 and tostring(err2):find("removed skeleton", 1, true), "the skeleton was not disposed after a listener error")
  else
    error("unknown listener way " .. tostring(how))
  end
end

assert(modes[mode], "unknown mode " .. tostring(mode))()
C.done()
