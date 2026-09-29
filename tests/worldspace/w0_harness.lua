-- W0: the worldspace harness itself (fixture, stub transform, SkeletonBounds probe), one mode per scenarios row.
local spine = require("plugin.spine")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local W = arg[0]:match("^(.*)/")
local mode = arg[1]

local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-9) end

local function boneNamed(obj, name)
  for _, b in ipairs(obj.bones) do if b.name == name then return b end end
end

local function loadFixture()
  return spine.loadSkeletonData(W .. "/assets/" .. os.getenv("SPINE_RUNTIME") .. "/hitboxes.json",
    spine.loadAtlas("spineboy/spineboy.atlas"))
end

-- the affine map T(x, y) * R(rotation) * S(xScale, yScale) of one object, as a 3x3 row-major matrix
local function matrix(p)
  local r = math.rad(p.rotation or 0)
  local c, s, sx, sy = math.cos(r), math.sin(r), p.xScale or 1, p.yScale or 1
  return { c * sx, -s * sy, p.x or 0, s * sx, c * sy, p.y or 0, 0, 0, 1 }
end
local function mul(a, b)
  local m = {}
  for i = 0, 2 do for j = 0, 2 do
    m[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1] + a[i * 3 + 2] * b[j + 4] + a[i * 3 + 3] * b[j + 7]
  end end
  return m
end

local modes = {}

function modes.fixture()
  local obj = spine.create(loadFixture())
  local order = table.concat(obj:getDrawOrder(), ",")
  print("setup draw order", order)
  C.expect(order == "boxA,boxB,boxC,boxSkin,boxSlid", "setup draw order is not slot order: " .. order)
  C.expect(boneNamed(obj, "chain3") ~= nil, "no chain3 bone")
  local chain1 = boneNamed(obj, "chain1")
  print("chain1 rotation/scale/shear", chain1.rotation, chain1.xScale, chain1.yScale, chain1.shearX, chain1.shearY)
  C.expect(chain1.xScale ~= chain1.yScale and chain1.shearX ~= 0 and chain1.rotation ~= 0, "chain1 is not rotated, non-uniformly scaled and sheared")

  obj:setAnimation(1, "reorder", false)
  obj:updateState(0)
  order = table.concat(obj:getDrawOrder(), ",")
  print("draw order after reorder", order)
  C.expect(order == "boxC,boxB,boxA,boxSkin,boxSlid", "drawOrder timeline did not reorder: " .. order)

  -- (200, 0) lies only in boxSkin; its bone is skin-only
  print("boxSkin before setSkin", __probe.boundsContains(obj, 200, 0))
  C.expect(__probe.boundsContains(obj, 200, 0) == nil, "boxSkin hit while its skin-only bone is inactive")
  obj:setSkin("extra")
  obj:updateState(0)
  print("boxSkin after setSkin", __probe.boundsContains(obj, 200, 0))
  C.expect(__probe.boundsContains(obj, 200, 0) == "boxSkin", "boxSkin not hit once skin extra is set")
  -- the oracle walks slot order: the first containing slot wins whatever the draw order
  C.expect(__probe.boundsContains(obj, 20, 20) == "boxA", "slot-order oracle did not return boxA at (20, 20)")
  obj:removeSelf()
end

function modes.stub()
  local outer = display.newGroup()
  outer.x, outer.y, outer.xScale, outer.yScale, outer.rotation = 100, 50, 2, 1.5, 30
  local inner = display.newGroup()
  outer:insert(inner)
  inner.x, inner.y, inner.xScale, inner.yScale, inner.rotation = -20, 40, 0.5, 0.75, -45
  local obj = spine.create(loadFixture())
  inner:insert(obj)
  obj.x, obj.y, obj.xScale, obj.yScale, obj.rotation = 10, -5, 1.25, 0.8, 60

  -- reached from C: the skeleton object's __index falls back to the group metatable for these keys
  local plain = display.newGroup()
  C.expect(obj.contentToLocal ~= nil and rawequal(obj.contentToLocal, plain.contentToLocal), "skeleton object does not reach the stub contentToLocal")
  C.expect(obj.localToContent ~= nil and rawequal(obj.localToContent, plain.localToContent), "skeleton object does not reach the stub localToContent")

  -- defaults inside the math: an untransformed group is the identity and gains no property
  local x, y = plain:localToContent(3, 4)
  C.expect(x == 3 and y == 4, "an untransformed group is not the identity")
  for _, k in ipairs({ "x", "y", "xScale", "yScale", "rotation" }) do
    C.expect(rawget(plain, "__props")[k] == nil, "the stub seeded " .. k)
  end

  local m = mul(mul(matrix(rawget(outer, "__props")), matrix(rawget(inner, "__props"))), matrix(rawget(obj, "__props")))
  for _, p in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 37.5, -12.25 }, { -200, 300 } }) do
    local cx, cy = obj:localToContent(p[1], p[2])
    local ex, ey = m[1] * p[1] + m[2] * p[2] + m[3], m[4] * p[1] + m[5] * p[2] + m[6]
    print(string.format("local (%g, %g) -> content (%.6f, %.6f), closed form (%.6f, %.6f)", p[1], p[2], cx, cy, ex, ey))
    C.expect(near(cx, ex) and near(cy, ey), "localToContent differs from the closed form at " .. p[1] .. "," .. p[2])
    local lx, ly = obj:contentToLocal(cx, cy)
    C.expect(near(lx, p[1]) and near(ly, p[2]), "contentToLocal does not invert localToContent at " .. p[1] .. "," .. p[2])
  end
  -- a moved skeleton object moves its content mapping
  local before = { obj:localToContent(0, 0) }
  obj.x = obj.x + 7
  local after = { obj:localToContent(0, 0) }
  C.expect(not near(before[1], after[1]) or not near(before[2], after[2]), "writing obj.x did not change localToContent")
  obj:removeSelf()
end

-- head-bb has no setup attachment, so no point hits until the scenario attaches head
function modes.probe()
  local data = spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas"))
  local group = display.newGroup()
  group.x, group.y, group.xScale, group.yScale, group.rotation = 160, 240, 0.5, 0.5, 20
  local obj = spine.create(data)
  group:insert(obj)
  local head = boneNamed(obj, "head")
  C.expect(__probe.boundsContains(obj, head.worldX, head.worldY) == nil, "head-bb hit before its attachment is set")
  obj:setAttachment("head-bb", "head")
  -- a grid around the head bone, sampled in content coordinates and mapped to skeleton space through the stub
  local hx, hy = obj:localToContent(head.worldX, head.worldY)
  local inside, outside, other = 0, 0, {}
  for i = -40, 40 do for j = -40, 40 do
    local lx, ly = obj:contentToLocal(hx + i * 2.5, hy + j * 2.5)
    local name = __probe.boundsContains(obj, lx, ly)
    if name == "head" then inside = inside + 1 elseif name == nil then outside = outside + 1 else other[name] = true end
  end end
  print("head grid: inside", inside, "outside", outside)
  C.expect(inside > 0, "no sampled point inside head-bb")
  C.expect(outside > 0, "no sampled point outside head-bb")
  C.expect(next(other) == nil, "a box other than head answered")
  C.expect(__probe.boundsContains(obj, 1e5, 1e5) == nil, "a far point hit a box")
  obj:removeSelf()
end

assert(modes[mode], "unknown mode " .. tostring(mode))()
C.done()
