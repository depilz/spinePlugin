-- Default anchors (I17): a mesh is re-centred on its vertex bounds and placed at their centre, so it draws in place
-- only at anchor 0.5. Under app defaults anchorX/anchorY 0 every live mesh must still read 0.5/0.5: after the first
-- draw (creation), after 10 frames (reuse), after split() (the split group's pass) and for meshes created after a
-- mid-run change of the defaults (every attachment hidden for a draw, so its meshes are removed, then shown again).
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock = C.mock
local function meshes(group, out)
  for _, c in ipairs(mock.children(group)) do if mock.kind(c) == "mesh" then out[#out + 1] = c end end
  return out
end
local function check(obj, label)
  local main = meshes(obj, {})
  local all = obj._splitGroup and meshes(obj._splitGroup, { unpack(main) }) or main
  local bad = 0
  for _, m in ipairs(all) do if m.anchorX ~= 0.5 or m.anchorY ~= 0.5 then bad = bad + 1 end end
  print(("%s: %d meshes (%d in the skeleton group), %d not at anchor 0.5/0.5; first %s/%s")
    :format(label, #all, #main, bad, tostring(all[1] and all[1].anchorX), tostring(all[1] and all[1].anchorY)))
  C.expect(#all > 0 and bad == 0, label .. ": every mesh reads anchor 0.5/0.5")
  return #main, #all - #main
end
local function setAnchor(x, y) display.setDefault("anchorX", x); display.setDefault("anchorY", y) end

setAnchor(0, 0)
local obj = C.spine.create(C.data("spineboy", 0.5))
obj:setAnimation(1, "idle", true)
C.frame(obj)
check(obj, "creation")
for _ = 1, 10 do C.frame(obj) end
check(obj, "reuse")
local order = obj:getDrawOrder()
obj._splitGroup = obj:split({ unpack(order, math.floor(#order / 2) + 1) })
C.frame(obj)
local _, inSplit = check(obj, "split")
C.expect(inSplit > 0, "split: the split group holds meshes")
setAnchor(1, 0.25)
local hidden = {}
for _, s in ipairs(obj.slots) do
  local slot = obj:getSlot(s.name)
  if slot.attachment then hidden[#hidden + 1] = { slot, slot.attachment }; slot.attachment = nil end
end
obj:draw() -- no updateState(): the animation would key attachments back
local removedAll = #meshes(obj, meshes(obj._splitGroup, {})) == 0
for _, h in ipairs(hidden) do h[1].attachment = h[2] end
local created = mock.stats.newMesh
obj:draw()
print(("default change: hiding every attachment left %s meshes; showing them created %d")
  :format(removedAll and "no" or "some", mock.stats.newMesh - created))
C.expect(removedAll and mock.stats.newMesh > created, "default change: the meshes are created anew")
check(obj, "default change")
obj:removeSelf()
setAnchor(0.5, 0.5)
C.done()
