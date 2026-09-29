-- W1: the bone world helpers bone:setWorldPosition/translateWorld/localToWorld/worldToLocal in skeleton space and
-- the read-only bone.worldX/worldY, one mode per scenarios row.
local spine = require("plugin.spine")
local S = __stub
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local W = arg[0]:match("^(.*)/")
local mode, how = arg[1], arg[2]
local EPS = 1e-3
local DEAD = "Bone belongs to a removed skeleton"
local METHODS = { "setWorldPosition", "translateWorld", "localToWorld", "worldToLocal" }

local function near(a, b, eps) return math.abs(a - b) <= (eps or EPS) end

local function boneNamed(obj, name)
  for _, b in ipairs(obj.bones) do if b.name == name then return b end end
  error("no bone " .. name)
end

local function spineboy()
  return spine.create(spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas")))
end
local function fixture()
  return spine.create(spine.loadSkeletonData(W .. "/assets/" .. os.getenv("SPINE_RUNTIME") .. "/hitboxes.json",
    spine.loadAtlas("spineboy/spineboy.atlas")))
end

-- sets bone to world (x, y), checks the world values wait for the next updateState, then equal the target
local function expectMovedTo(obj, bone, x, y)
  local wx, wy = bone.worldX, bone.worldY
  bone:setWorldPosition(x, y)
  C.expect(bone.worldX == wx and bone.worldY == wy, bone.name .. ": world values changed before updateState")
  obj:updateState(0)
  print(string.format("%s -> (%g, %g): world (%.6f, %.6f)", bone.name, x, y, bone.worldX, bone.worldY))
  C.expect(near(bone.worldX, x) and near(bone.worldY, y), bone.name .. ": world position is not the target after updateState")
end

local modes = {}

function modes.roundtrip()
  for _, obj in ipairs({ spineboy(), fixture() }) do
    local worst = 0
    for _, bone in ipairs(obj.bones) do
      for _, p in ipairs({ { 0, 0 }, { 13.5, -7.25 }, { -120, 45 } }) do
        local lx, ly = bone:worldToLocal(bone:localToWorld(p[1], p[2]))
        worst = math.max(worst, math.abs(lx - p[1]), math.abs(ly - p[2]))
      end
    end
    print(#obj.bones .. " bones, worst round-trip error", worst)
    C.expect(worst <= EPS, "worldToLocal(localToWorld(p)) differs from p by " .. worst)
    -- localToWorld(0, 0) is the bone's world position
    local last = obj.bones[#obj.bones]
    local x, y = last:localToWorld(0, 0)
    C.expect(near(x, last.worldX) and near(y, last.worldY), last.name .. ": localToWorld(0, 0) is not its world position")
    obj:removeSelf()
  end
end

function modes.setworld()
  local obj = fixture()
  expectMovedTo(obj, boneNamed(obj, "root"), 25, -40)
  expectMovedTo(obj, boneNamed(obj, "chain2"), 130, 60)
  expectMovedTo(obj, boneNamed(obj, "chain3"), -75, 210)
  -- the unkeyed writes survive later updates
  obj:updateState(0.5)
  local chain3 = boneNamed(obj, "chain3")
  C.expect(near(chain3.worldX, -75) and near(chain3.worldY, 210), "an unkeyed bone lost its write on a later update")
  obj:removeSelf()

  local boy = spineboy()
  expectMovedTo(boy, boneNamed(boy, "root"), 12, 34)
  expectMovedTo(boy, boneNamed(boy, "crosshair"), 150, -300)
  expectMovedTo(boy, boneNamed(boy, "head"), 40, -420)
  boy:removeSelf()
end

function modes.translate()
  for _, name in ipairs({ "root", "chain2", "chain3" }) do
    local a, b = fixture(), fixture()
    local ba, bb = boneNamed(a, name), boneNamed(b, name)
    ba:translateWorld(17, -9)
    bb:setWorldPosition(bb.worldX + 17, bb.worldY - 9)
    a:updateState(0); b:updateState(0)
    print(string.format("%s: translateWorld (%.6f, %.6f), setWorldPosition (%.6f, %.6f)", name, ba.worldX, ba.worldY, bb.worldX, bb.worldY))
    C.expect(near(ba.worldX, bb.worldX) and near(ba.worldY, bb.worldY), name .. ": translateWorld differs from setWorldPosition(world + d)")
    -- two translations before an update add up: the second starts from the first's pose, not the stale world value
    local x, y = ba.worldX, ba.worldY
    ba:translateWorld(5, 5); ba:translateWorld(5, 5)
    a:updateState(0)
    C.expect(near(ba.worldX, x + 10) and near(ba.worldY, y + 10), name .. ": two translateWorld calls did not add up")
    a:removeSelf(); b:removeSelf()
  end
end

function modes.keyed()
  -- "walk" keys hip's translation; a second, unwritten spineboy is the reference
  local a, b = spineboy(), spineboy()
  for _, o in ipairs({ a, b }) do o:setAnimation(1, "walk", true); o:updateState(0.1) end
  local hip = boneNamed(a, "hip")
  hip:setWorldPosition(hip.worldX + 300, hip.worldY + 300)
  a:updateState(0); b:updateState(0)
  local ref = boneNamed(b, "hip")
  print(string.format("keyed hip (%.6f, %.6f), reference (%.6f, %.6f)", hip.worldX, hip.worldY, ref.worldX, ref.worldY))
  C.expect(near(hip.worldX, ref.worldX) and near(hip.worldY, ref.worldY), "the animation did not overwrite a keyed bone's write")
  a:removeSelf(); b:removeSelf()
end

function modes.readonly()
  local obj = spineboy()
  local bone = boneNamed(obj, "crosshair")
  local x, y = bone.worldX, bone.worldY
  S.raises("worldX is read-only; use bone:setWorldPosition(x, y)", function() bone.worldX = 1 end)
  S.raises("worldY is read-only; use bone:setWorldPosition(x, y)", function() bone.worldY = 1 end)
  obj:updateState(0)
  C.expect(bone.worldX == x and bone.worldY == y, "a rejected world write changed the bone")
  obj:removeSelf()
end

function modes.rootscale()
  local obj = fixture()
  local root, chain2 = boneNamed(obj, "root"), boneNamed(obj, "chain2")
  -- the general root formula: world = pose * skeleton scale + skeleton position (scale Y carries Y-down's sign)
  __probe.setSkeletonTransform(obj, 30, -20, 2, 0.5)
  obj:updateState(0)
  expectMovedTo(obj, root, 90, 70)
  expectMovedTo(obj, chain2, -40, 15)
  __probe.setSkeletonTransform(obj, 0, 0, 0, 1)
  S.raises("Cannot set a root bone's world position when skeleton scale is zero", function() root:setWorldPosition(1, 2) end)
  S.raises("Cannot set a root bone's world position when skeleton scale is zero", function() root:translateWorld(1, 2) end)
  __probe.setSkeletonTransform(obj, 0, 0, 1, 0)
  S.raises("Cannot set a root bone's world position when skeleton scale is zero", function() root:setWorldPosition(1, 2) end)
  __probe.setSkeletonTransform(obj, 0, 0, 1, 1)
  obj:updateState(0)
  expectMovedTo(obj, chain2, 5, 6)
  obj:removeSelf()
end

function modes.badargs()
  local obj = spineboy()
  local bone = obj.bones[1]
  for _, m in ipairs(METHODS) do
    S.raises("bad argument", function() bone[m](bone, "x", 1) end)
    S.raises("bad argument", function() bone[m](bone, 1) end)
  end
  obj:removeSelf()
end

function modes.content()
  local outer = display.newGroup()
  outer.x, outer.y, outer.xScale, outer.yScale, outer.rotation = 160, 240, 0.6, 0.6, 25
  local inner = display.newGroup()
  outer:insert(inner)
  inner.x, inner.y, inner.xScale, inner.yScale, inner.rotation = 30, -15, 1.4, 0.9, -40
  for _, case in ipairs({ { obj = spineboy(), bone = "crosshair", anim = "aim" }, { obj = fixture(), bone = "chain3" } }) do
    local obj = case.obj
    inner:insert(obj)
    obj.x, obj.y, obj.xScale, obj.yScale, obj.rotation = -10, 20, 0.75, 0.75, 15
    if case.anim then obj:setAnimation(1, case.anim, true) end
    obj:updateState(0)
    local bone = boneNamed(obj, case.bone)
    local worst = 0
    for _, p in ipairs({ { 100, 100 }, { 200, 300 }, { 50, 420 }, { 280, 60 }, { 160, 240 }, { 10, 10 } }) do
      bone:setWorldPosition(obj:contentToLocal(p[1], p[2]))
      obj:updateState(0)
      local cx, cy = obj:localToContent(bone.worldX, bone.worldY)
      worst = math.max(worst, math.abs(cx - p[1]), math.abs(cy - p[2]))
    end
    print(case.bone .. ": worst content error", worst)
    C.expect(worst <= 0.5, case.bone .. ": the bone lands " .. worst .. " content px from the touch point")
    obj:removeSelf()
  end
end

-- the four methods, fetched from a live bone, each called on a stale one must raise DEAD
local function expectStale(bone, fns, where)
  for _, m in ipairs(METHODS) do
    local ok, err = pcall(fns[m], bone, 1, 2)
    print(where, m, ok, err)
    C.expect(not ok and tostring(err):find(DEAD, 1, true), where .. ": " .. m .. " did not raise '" .. DEAD .. "'")
  end
end

-- fetch each method from a live bone: indexing a stale bone raises first
function modes.stale()
  local obj = spineboy()
  local fns = {}
  for _, m in ipairs(METHODS) do fns[m] = obj.bones[1][m] end
  local ways = {
    removed = function() return obj.bones[2] end,
    parent = function() return boneNamed(obj, "head").parent end,
    children = function() return boneNamed(obj, "root").children[1] end,
    slot = function() return obj:getSlot("head").bone end,
    iktarget = function() return obj.ikConstraints[1].target end,
  }
  if ways[how] then
    local bone = ways[how]()
    C.expect(bone ~= nil, "no bone reached " .. how)
    bone:translateWorld(0, 0)
    obj:removeSelf(); S.frame(); S.gcfull()
    expectStale(bone, fns, how)
  elseif how == "window" then
    local bone = boneNamed(obj, "crosshair")
    local inFinalize
    obj:addEventListener("finalize", function() inFinalize = { pcall(bone.localToWorld, bone, 0, 0) } end)
    obj:removeSelf()
    S.endFrame()                                 -- finalize (the object still works), then RestoreTable
    C.expect(inFinalize and inFinalize[1] and type(inFinalize[2]) == "number", "the skeleton's own finalize listener could not use a bone")
    expectStale(bone, fns, how)
    S.frame()
    expectStale(bone, fns, how .. " after the next frame")
  elseif how == "finalize" then
    local bone = boneNamed(obj, "crosshair")
    obj:removeSelf(); S.frame()
    local other = display.newGroup()
    local called = false
    other:addEventListener("finalize", function() called = true; expectStale(bone, fns, how) end)
    other:removeSelf(); S.endFrame()
    C.expect(called, "the other object's finalize listener did not run")
  else
    error("unknown stale way " .. tostring(how))
  end
end

assert(modes[mode], "unknown mode " .. tostring(mode))()
C.done()
