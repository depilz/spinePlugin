-- A skeleton removed by its own injection listener mid-draw: the draw stops at once (the disposeRequested bails),
-- no later listener runs, no mesh is created and none of the removed group's meshes is touched again.
-- arg[1] names the bail that must hold:
--   visible       renderCommands after the visible call: a second listener on the same slot is not called
--   unsplit       skeletonRender after the only pass: the unused-mesh cleanup does not run on the removed meshes
--   split-first   skeletonRender after the first split pass: the split group's pass does not run
--   split-second  skeletonRender after the split group's pass: the unused-mesh cleanup does not run
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock = C.mock
local mode = arg[1]
local obj = C.spine.create(C.data("raptor", 0.5))
obj:setAnimation(1, "walk", true)
local order = obj:getDrawOrder()
local mid, top = order[math.floor(#order / 2)], order[#order]
local armed, late, atRemoval = false, 0, nil
local function stat(k) return mock.stats[k] or 0 end
local function remover(e)
  if not (armed and e.isVisible) then return end
  obj:removeSelf()
  atRemoval = { newMesh = stat("newMesh"), meshRemoveSelf = stat("meshRemoveSelf") }
end
local function counter(e) if armed and e.isVisible then late = late + 1 end end
local function inject(slot, listener) obj:inject(display.newRect(0, 0, 10, 10), slot, listener) end

if mode == "visible" then
  inject(mid, remover); inject(mid, counter)
elseif mode == "unsplit" then
  inject(mid, remover)                        -- the meshes after mid go unused in the removing pass
elseif mode == "split-first" then
  obj._splitGroup = obj:split({ top })
  inject(mid, remover); inject(top, counter)  -- remover in the first pass, counter in the split group's
elseif mode == "split-second" then
  obj._splitGroup = obj:split({ top })
  inject(top, remover)
else
  error("t20_dispose_bail: unknown mode " .. tostring(mode))
end
C.frame(obj)                                  -- fills the mesh pool
if mode == "split-second" then obj:setAttachment(order[1], nil) end  -- a main mesh goes unused in the removing frame

armed = true
local draw = obj.draw
obj:updateState(16.666)
local ok, err = pcall(draw, obj)
C.expect(atRemoval, "the listener did not remove the skeleton")
atRemoval = atRemoval or { newMesh = 0, meshRemoveSelf = 0 }
-- counted from the removal on: removeSelf's own split-mesh removal is before it
local created, removed = stat("newMesh") - atRemoval.newMesh, stat("meshRemoveSelf") - atRemoval.meshRemoveSelf
print(("%s: draw ok=%s, then: later listener calls %d, meshes created %d, mesh removeSelf %d%s"):format(mode,
  tostring(ok), late, created, removed, ok and "" or " (" .. tostring(err) .. ")"))
C.expect(ok, "the removing draw raised: " .. tostring(err))
C.expect(late == 0, "a listener was called after an earlier listener removed the skeleton")
C.expect(created == 0 and removed == 0, "the removing draw created or removed meshes after the removal")
C.done()
