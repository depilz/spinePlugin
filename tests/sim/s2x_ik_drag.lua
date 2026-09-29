-- S2x IK drag: the InverseKinematics example's drag (crosshair:setWorldPosition(o:contentToLocal(...))) driven by
-- dispatched touch events on spineboy inside a moved and scaled parent group ("scaled"), also rotated ("rotated").
-- The dragged bone is the crosshair; after each moved point's updateState it maps back through localToContent to
-- within 0.5 content px of the touch.
local L = require("simlib")
L.watchdogMs = 20000
local MODE = L.arg
L.open("s2x_ik_drag " .. MODE)
local POINTS = { { 300, 420 }, { 520, 380 }, { 610, 600 }, { 200, 700 }, { 420, 250 }, { 150, 520 } }
local checks = { "crosshair" }
for i = 1, #POINTS do checks[i + 1] = "point " .. i end
L.expect(unpack(checks))
local spine = L.loadPlugin()
local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.6)

local scene = display.newGroup()
local parent = display.newGroup()
scene:insert(parent)
parent.x, parent.y, parent.xScale, parent.yScale = 40, -30, 1.3, 0.8
if MODE == "rotated" then parent.rotation = 20 end
local o = spine.create(data)
parent:insert(o)
o.x, o.y = display.contentCenterX, display.contentCenterY + 100
o:setAnimation(1, o:getAnimations()[1], true)
o:updateState(0); o:draw()

-- the example's listener (Corona/tests/InverseKinematics.lua)
local crosshair = o:getIKConstraint("aim-ik").target
local prevX, prevY
o:addEventListener("touch", function(event)
  if not prevX and event.phase ~= "began" then return end

  if event.phase == "began" then
    prevX, prevY = event.x, event.y
    o.stage:setFocus(event.target)

  elseif event.phase == "moved" then
    crosshair:setWorldPosition(o:contentToLocal(event.x, event.y))

  elseif event.phase == "ended" or event.phase == "cancelled" then
    prevX, prevY = nil, nil
    o.stage:setFocus(nil)
  end
end)

L.check("crosshair", crosshair.name == "crosshair", crosshair.name, "animation", o:getAnimations()[1])
o:dispatchEvent({ name = "touch", phase = "began", x = 384, y = 512, target = o })
for i, p in ipairs(POINTS) do
  o:dispatchEvent({ name = "touch", phase = "moved", x = p[1], y = p[2], target = o })
  o:updateState(1000 / 60); o:draw()
  local cx, cy = o:localToContent(crosshair.worldX, crosshair.worldY)
  local d = math.sqrt((cx - p[1]) ^ 2 + (cy - p[2]) ^ 2)
  L.check(checks[i + 1], d <= 0.5, ("touch %g,%g crosshair %.4f,%.4f distance %.4f"):format(p[1], p[2], cx, cy, d))
  local mark = display.newCircle(scene, p[1], p[2], 6)
  mark:setFillColor(1, 0, 0, 0.6)
end
o:dispatchEvent({ name = "touch", phase = "ended", x = POINTS[#POINTS][1], y = POINTS[#POINTS][2], target = o })

timer.performWithDelay(100, function()
  local name = "s2x_ik_drag_" .. MODE .. ".png"
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
