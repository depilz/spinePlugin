-- World transform is only computed in draw(): what do Lua reads see after updateState()?
local fx = require("realdata_fixture")
local failed = 0
local function expect(ok, msg) if not ok then failed = failed + 1; print("CHECK FAILED: " .. msg) end end
local function near(a, b) return math.abs(a - b) < 0.01 end
local data = fx.loadData("raptor/raptor.atlas", "raptor/raptor.skel", 0.5)
local obj = fx.create(data)
local b0 = obj:getBounds()
print(("getBounds() right after create (no draw yet): xMin=%.1f yMin=%.1f xMax=%.1f yMax=%.1f"):format(b0.xMin, b0.yMin, b0.xMax, b0.yMax))
fx.worldTransform(obj)
local b1 = obj:getBounds()
print(("getBounds() after a world-transform update:   xMin=%.1f yMin=%.1f xMax=%.1f yMax=%.1f"):format(b1.xMin, b1.yMin, b1.xMax, b1.yMax))
expect(near(b0.xMin, b1.xMin) and near(b0.yMin, b1.yMin) and near(b0.xMax, b1.xMax) and near(b0.yMax, b1.yMax), "getBounds before the first draw is not the world bounds (render-12)")
local s = obj:getSize()
print(("getSize(): width=%.1f height=%.1f offsetX=%.1f offsetY=%.1f  (offsetX = xMin, offsetY = -yMin)"):format(s.width, s.height, s.offsetX, s.offsetY))
local head
for _, b in ipairs(obj.bones) do if b.name == "raptor-head" or b.name == "head" then head = b end end
head = head or obj.bones[#obj.bones]
obj:setAnimation(1, "walk", true)
local x0 = head.worldX
obj:updateState(400)
local x1 = head.worldX
fx.worldTransform(obj)
local x2 = head.worldX
print(("bone '%s' worldX: before=%.2f, after updateState(400)=%.2f (unchanged), after world transform=%.2f"):format(head.name, x0, x1, x2))
expect(near(x1, x2), "bone world position stale after updateState (render-12)")
if failed > 0 then error(failed .. " check(s) failed", 0) end
