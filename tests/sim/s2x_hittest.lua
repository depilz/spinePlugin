-- S2x hitTest: skeleton:hitTest in content coordinates on spineboy inside a moved and scaled group (head hits, a far
-- point misses), and the real engine's contentToLocal/localToContent on a nested moved/scaled/rotated group chain
-- against the closed form the headless stub uses (tests/lifecycle/solar2d_stub.lua).
local L = require("simlib")
L.watchdogMs = 20000
L.open("s2x_hittest")
L.expect("head", "outside", "fidelity")
local spine = L.loadPlugin()
local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 1)

local scene = display.newGroup()
local parent = display.newGroup()
scene:insert(parent)
parent.x, parent.y, parent.xScale, parent.yScale = 60, -40, 0.7, 0.9
local o = spine.create(data)
parent:insert(o)
o.x, o.y = display.contentCenterX, display.contentCenterY + 300
o:setAttachment("head-bb", "head")
o:updateState(0); o:draw()

local head
for _, b in ipairs(o.bones) do if b.name == "head" then head = b end end
local hx, hy = o:localToContent(head:localToWorld(113, 0)) -- inside the head box (vertex mean of head-bb)
local hit = o:hitTest(hx, hy)
L.check("head", hit ~= nil and hit.attachmentName == "head" and hit.slotName == "head-bb",
  ("at %.2f,%.2f: %s %s"):format(hx, hy, tostring(hit and hit.slotName), tostring(hit and hit.attachmentName)))
local miss = o:hitTest(20, 20)
L.check("outside", miss == nil, "at 20,20: " .. tostring(miss and miss.slotName))

-- the stub's closed form: T(x, y) * R(rotation) * S(xScale, yScale) per object, up the parent chain to the stage
local function chain(t)
  local objects = {}
  while t do objects[#objects + 1] = t; t = t.parent end
  return objects
end
local function toContent(t, x, y)
  for _, g in ipairs(chain(t)) do
    local r = math.rad(g.rotation)
    local c, s = math.cos(r), math.sin(r)
    x, y = x * g.xScale, y * g.yScale
    x, y = g.x + x * c - y * s, g.y + x * s + y * c
  end
  return x, y
end
local function toLocal(t, x, y)
  local objects = chain(t)
  for i = #objects, 1, -1 do
    local g = objects[i]
    local r = math.rad(g.rotation)
    local c, s = math.cos(r), math.sin(r)
    x, y = x - g.x, y - g.y
    x, y = (x * c + y * s) / g.xScale, (y * c - x * s) / g.yScale
  end
  return x, y
end
local outer = display.newGroup()
outer.x, outer.y, outer.xScale, outer.yScale, outer.rotation = 160, 240, 0.8, 0.6, 25
local inner = display.newGroup()
outer:insert(inner)
inner.x, inner.y, inner.xScale, inner.yScale, inner.rotation = 30, -15, 1.4, 0.9, -40
local leaf = spine.create(data)
inner:insert(leaf)
leaf.x, leaf.y, leaf.xScale, leaf.yScale, leaf.rotation = -10, 20, 0.75, 1.2, 15
local worst = 0
for _, p in ipairs({ { 0, 0 }, { 100, -50 }, { -250, 300 }, { 37.5, 412.25 } }) do
  local ax, ay = leaf:localToContent(p[1], p[2])
  local bx, by = toContent(leaf, p[1], p[2])
  local lx, ly = leaf:contentToLocal(p[1], p[2])
  local mx, my = toLocal(leaf, p[1], p[2])
  worst = math.max(worst, math.abs(ax - bx), math.abs(ay - by), math.abs(lx - mx), math.abs(ly - my))
end
L.check("fidelity", worst <= 1e-3, ("max difference %.6g"):format(worst))
leaf:removeSelf(); outer:removeSelf()

timer.performWithDelay(100, function()
  local mark = display.newCircle(scene, hx, hy, 6)
  mark:setFillColor(1, 0, 0, 0.6)
  local name = "s2x_hittest.png"
  display.save(scene, { filename = name, baseDir = system.TemporaryDirectory, captureOffscreenArea = true })
  local fi = io.open(system.pathForFile(name, system.TemporaryDirectory), "rb")
  if fi then
    local bytes = fi:read("*a"); fi:close()
    local fo = assert(io.open(L.dir .. "/" .. name, "wb")); fo:write(bytes); fo:close()
    L.log("saved", name, #bytes, "bytes")
  else
    L.log("missing", name)
  end
  L.finish(0)
end)
