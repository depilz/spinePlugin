-- S28 (I17): every mesh draws in the same place whatever display.setDefault("anchorX"/"anchorY") the app uses.
-- spineboy idle at 200,400, scale 0.5, one skeleton per default anchor 0.5 (the reference), 0, 1 and 0.25, each created,
-- stepped and drawn under its default. Bounds are contentBounds, equal within TOL px.
-- CHECK creation: each skeleton's bounds after updateState(0) + draw() equal the reference's.
-- CHECK reuse: the same over 30 frames of updateState(16), frame by frame.
-- CHECK split: after split() of the second half of the draw order, both groups' bounds equal the reference's.
-- CHECK default_change: a skeleton created and drawn at 0.5 whose meshes are all created anew after setDefault 0
--   (every attachment hidden for a draw, so no mesh child is left, then shown again) keeps its bounds.
-- CHECK control: the reference's bounds equal the line's pre-fix ones (CONTROL, measured on 2.0.0 and 3.0.0).
local L = require("simlib")
L.watchdogMs = 30000
L.open("s28_default_anchor")
L.expect("creation", "reuse", "split", "default_change", "control")
local TOL = 0.05
local ANCHORS = { 0.5, 0, 1, 0.25 }
-- xMin, yMin, xMax, yMax of the 0.5 reference after updateState(0) + draw(), measured on 2.0.0 and 3.0.0 (8aafc42)
local CONTROL = {
  ["plugin.spine42"] = { 120.388, 76.687, 347.442, 404.086 },
  ["plugin.spine43"] = { 120.388, 76.687, 347.442, 404.086 },
}
local spine = L.loadPlugin()
local gidx = getmetatable(display.newGroup()).__index -- Solar2D's group __index, as the skeleton's may shadow it
local saved = { display.getDefault("anchorX"), display.getDefault("anchorY") }
local function setAnchor(x, y) display.setDefault("anchorX", x); display.setDefault("anchorY", y or x) end
local function kinds(group)
  local t = {}
  for i = 1, gidx(group, "numChildren") do
    local c = gidx(group, i)
    t[#t + 1] = tostring(c.path and c.path.type or "?")
  end
  return t
end
local function bounds(group)
  local b = gidx(group, "contentBounds")
  return { b.xMin, b.yMin, b.xMax, b.yMax }
end
local function fmt(b) return ("%.3f,%.3f,%.3f,%.3f"):format(b[1], b[2], b[3], b[4]) end
local function near(a, b)
  for i = 1, 4 do if math.abs(a[i] - b[i]) > TOL then return false end end
  return true
end

local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.5)
local function newSkeleton()
  local sk = spine.create(data)
  sk.x, sk.y = 200, 400
  sk:setAnimation(1, "idle", true)
  sk:updateState(0); sk:draw()
  return sk
end

-- creation
local skeletons, created = {}, {}
for i, a in ipairs(ANCHORS) do
  setAnchor(a)
  skeletons[i] = newSkeleton()
  created[i] = bounds(skeletons[i])
  L.log("creation", "anchor", a, fmt(created[i]))
end
local ok, detail = true, {}
for i = 2, #ANCHORS do
  if not near(created[i], created[1]) then ok = false; detail[#detail + 1] = ANCHORS[i] .. ":" .. fmt(created[i]) end
end
L.check("creation", ok, "reference", fmt(created[1]), table.concat(detail, " "))

-- reuse
local bad, firstBad = 0, nil
for frame = 1, 30 do
  local ref
  for i, a in ipairs(ANCHORS) do
    setAnchor(a)
    skeletons[i]:updateState(16); skeletons[i]:draw()
    local b = bounds(skeletons[i])
    ref = ref or b
    if not near(b, ref) then
      bad = bad + 1
      firstBad = firstBad or ("frame %d anchor %s %s vs %s"):format(frame, a, fmt(b), fmt(ref))
    end
  end
end
L.check("reuse", bad == 0, "mismatches", bad, firstBad or "")

-- split
local order = skeletons[1]:getDrawOrder()
local inSplit = { unpack(order, math.floor(#order / 2) + 1) }
local splitRef
ok, detail = true, {}
for i, a in ipairs(ANCHORS) do
  setAnchor(a)
  local g = skeletons[i]:split(inSplit)
  skeletons[i]:draw()
  local b = { main = bounds(skeletons[i]), split = bounds(g) }
  L.log("split", "anchor", a, "main", fmt(b.main), "split", fmt(b.split))
  splitRef = splitRef or b
  if not (near(b.main, splitRef.main) and near(b.split, splitRef.split)) then
    ok = false; detail[#detail + 1] = ("%s:%s/%s"):format(a, fmt(b.main), fmt(b.split))
  end
end
L.check("split", ok, "reference", fmt(splitRef.main), fmt(splitRef.split), table.concat(detail, " "))
for _, sk in ipairs(skeletons) do sk:removeSelf() end

-- default_change
setAnchor(0.5)
local sk = newSkeleton()
local before = bounds(sk)
setAnchor(0)
local hidden = {}
for _, s in ipairs(sk.slots) do
  local slot = sk:getSlot(s.name)
  if slot.attachment then hidden[#hidden + 1] = { slot, slot.attachment }; slot.attachment = nil end
end
sk:draw() -- no updateState(): the animation would key attachments back
local whileHidden = kinds(sk)
local emptied = not table.concat(whileHidden, ","):find("mesh")
for _, h in ipairs(hidden) do h[1].attachment = h[2] end
sk:draw()
local after = bounds(sk)
L.log("default_change", "hidden", #hidden, "children while hidden", table.concat(whileHidden, ","), fmt(before), fmt(after))
L.check("default_change", emptied and near(after, before), "before", fmt(before), "after", fmt(after))
sk:removeSelf()

-- control
local control = CONTROL[L.plugin]
L.check("control", control ~= nil and near(created[1], control), L.plugin, fmt(created[1]), control and fmt(control) or "none")

setAnchor(saved[1], saved[2])
L.log("defaults restored", display.getDefault("anchorX"), display.getDefault("anchorY"))
timer.performWithDelay(100, function() L.finish(0) end)
