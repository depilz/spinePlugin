-- S26 (4.3 only): attachment:copy{ region } and skeleton:createAttachment draw the region they name. Four spineboys
-- each show one slot only: the crosshair slot's own "crosshair" region (the control), the front-bracer slot's own
-- region, a front-bracer copy remapped to "crosshair" and a region attachment created on "crosshair". A region's UV
-- sum is the same whichever quad shows it, so each one's mesh UV sums are compared.
-- CHECK control: both reference quads draw the same vertex count (> 0), and the two regions' UV sums differ (the
--               observable tells regions apart)
-- CHECK remap: the remapped copy draws as many vertices with the crosshair UV sums, not the front-bracer ones
-- CHECK create: the created attachment draws as many vertices with the crosshair UV sums
-- CHECK mesh: a mouth-grind mesh copy remapped to "mouth-oooo" draws the mouth-oooo mesh's UV sums, not its own (the two
--             meshes share their UVs and triangles, so only the region tells them apart)
local L = require("simlib")
L.watchdogMs = 20000
L.open("s26_region")
L.expect("control", "remap", "create", "mesh")
local spine = L.loadPlugin()
local gidx = getmetatable(display.newGroup()).__index -- Solar2D's group __index, to read real children

-- uvSums(group): the number of mesh vertices the group draws and their u, v sums
local function uvSums(group)
  local nv, su, sv = 0, 0, 0
  for i = 1, gidx(group, "numChildren") do
    local p = gidx(group, i).path
    if p and p.type == "mesh" then
      local k = 1
      while true do
        local ok, u, v = pcall(p.getUV, p, k)
        if not ok or u == nil then break end
        nv, su, sv = nv + 1, su + u, sv + v
        k = k + 1
      end
    end
  end
  return nv, su, sv
end

local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.3)
-- only(slotName, attachment, label): a spineboy showing only slotName, with attachment (an Attachment or a name)
local function only(slotName, attachment, label)
  local obj = spine.create(data)
  obj.x, obj.y = 384, 800
  for _, name in ipairs(obj:getSlotNames()) do obj:getSlot(name).attachment = nil end
  obj:getSlot(slotName).attachment = attachment
  for _ = 1, 3 do obj:updateState(16); obj:draw() end
  local nv, su, sv = uvSums(obj)
  L.log(label, "vertices", nv, ("%.5f %.5f"):format(su, sv))
  return { nv = nv, su = su, sv = sv }
end
local function same(a, b) return a.nv == b.nv and math.abs(a.su - b.su) < 1e-4 and math.abs(a.sv - b.sv) < 1e-4 end

local source = spine.create(data)
local bracer = source:getSlot("front-bracer").attachment
local crosshair = only("crosshair", "crosshair", "crosshair")
local own = only("front-bracer", bracer, "front-bracer")
local remapped = only("front-bracer", bracer:copy({ region = "crosshair" }), "remapped")
local created = only("front-bracer", source:createAttachment({ region = "crosshair", name = "made" }), "created")
L.check("control", crosshair.nv > 0 and own.nv == crosshair.nv and not same(crosshair, own), "vertices", crosshair.nv,
  own.nv)
L.check("remap", same(remapped, crosshair) and not same(remapped, own), "vertices", remapped.nv)
L.check("create", same(created, crosshair), "vertices", created.nv)
local default = source:findSkin("default")
local grind = default:getAttachment("mouth", "mouth-grind")
local grindOwn = only("mouth", grind, "mouth-grind")
local oooo = only("mouth", default:getAttachment("mouth", "mouth-oooo"), "mouth-oooo")
local meshRemapped = only("mouth", grind:copy({ region = "mouth-oooo" }), "mesh-remapped")
L.check("mesh", grind.type == "mesh" and oooo.nv > 0 and not same(grindOwn, oooo) and same(meshRemapped, oooo),
  "vertices", meshRemapped.nv)
timer.performWithDelay(300, function() L.finish(0) end)
