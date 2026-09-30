-- S27 (4.3 only): obj.sliders draws. Three diamonds whose slider "rotation" is written from Lua: two at time 0 (the
-- control), one a quarter into the slider's animation. After 5 frames each one's mesh vertex sums are compared.
-- CHECK control: the two time-0 diamonds draw vertices, and the same ones (the observable is not noisy)
-- CHECK time: the diamond whose slider time was written elsewhere draws different vertices
local L = require("simlib")
L.watchdogMs = 20000
L.open("s27_slider")
L.expect("control", "time")
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

local atlas = spine.loadAtlas("spines/diamond/diamond.atlas")
local data = spine.loadSkeletonData("spines/diamond/diamond.skel", atlas, 0.4)
-- scrubbed(fraction): a diamond whose slider time is written to that fraction of its duration, 5 frames on
local function scrubbed(fraction)
  local obj = spine.create(data)
  obj.x, obj.y = 384, 600
  local slider = obj.sliders.rotation
  slider.time = slider.duration * fraction
  for _ = 1, 5 do obj:updateState(16); obj:draw() end
  local nv, sx, sy = vertexSums(obj)
  L.log("time", slider.time, "boneDriven", slider.boneDriven, "vertices", nv, ("%.4f %.4f"):format(sx, sy))
  return { nv = nv, sx = sx, sy = sy }
end
local function same(a, b) return a.nv == b.nv and math.abs(a.sx - b.sx) < 1e-3 and math.abs(a.sy - b.sy) < 1e-3 end

local control, again, moved = scrubbed(0), scrubbed(0), scrubbed(0.25)
L.check("control", control.nv > 0 and same(control, again), "vertices", control.nv, again.nv)
L.check("time", not same(control, moved), "vertices", control.nv, moved.nv)
timer.performWithDelay(300, function() L.finish(0) end)
