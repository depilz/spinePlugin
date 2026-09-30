-- S25 (4.3 only): trackEntry.additive draws. Three spineboys walk on track 1 and aim on track 2; two replace (the
-- control), one adds. After 20 frames each one's mesh vertex sums are compared.
-- CHECK control: the two replacing spineboys draw vertices, and the same ones (the observable is not noisy)
-- CHECK additive: the adding spineboy's vertices differ from the replacing control's
local L = require("simlib")
L.watchdogMs = 20000
L.open("s25_additive")
L.expect("control", "additive")
local spine = L.loadPlugin()
local gidx = getmetatable(display.newGroup()).__index -- Solar2D's group __index, to read real children

-- vertexSums(group): the number of mesh vertices the group draws and their x, y sums
local function vertexSums(group)
  local nv, sx, sy = 0, 0, 0
  for i = 1, gidx(group, "numChildren") do
    local p = gidx(group, i).path
    if p and p.type == "mesh" then
      local k = 1
      while true do
        local ok, x, y = pcall(p.getVertex, p, k)
        if not ok or x == nil then break end
        nv, sx, sy = nv + 1, sx + x, sy + y
        k = k + 1
      end
    end
  end
  return nv, sx, sy
end

local atlas = spine.loadAtlas("spines/spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spines/spineboy/spineboy.skel", atlas, 0.3)
-- aiming(additive): a spineboy walking on track 1 and aiming on track 2 with the given additive flag, 20 frames on
local function aiming(additive)
  local obj = spine.create(data)
  obj.x, obj.y = 384, 800
  obj:setAnimation(1, "walk", true)
  obj:setAnimation(2, "aim", true).additive = additive
  for _ = 1, 20 do obj:updateState(16); obj:draw() end
  local nv, sx, sy = vertexSums(obj)
  L.log("additive", additive, "vertices", nv, ("%.4f %.4f"):format(sx, sy))
  return { nv = nv, sx = sx, sy = sy }
end
local function same(a, b) return a.nv == b.nv and math.abs(a.sx - b.sx) < 1e-3 and math.abs(a.sy - b.sy) < 1e-3 end

local replace, again, add = aiming(false), aiming(false), aiming(true)
L.check("control", replace.nv > 0 and same(replace, again), "vertices", replace.nv, again.nv)
L.check("additive", not same(replace, add), "vertices", replace.nv, add.nv)
timer.performWithDelay(300, function() L.finish(0) end)
