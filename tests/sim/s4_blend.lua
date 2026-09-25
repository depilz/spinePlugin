-- S4 (render-6): blend mode of a reused mesh after its texture changes (mesh.fill = {...}).
local L = require("simlib")
L.watchdogMs = 20000
L.open("s4_blend")
local spine = L.loadPlugin()
local gidx = getmetatable(display.newGroup()).__index
local function children(obj)
  local t = {}
  for i = 1, gidx(obj, "numChildren") do t[#t + 1] = gidx(obj, i) end
  return t
end
local function blendSummary(obj)
  local counts, list = {}, {}
  for i, c in ipairs(children(obj)) do
    local b = c.blendMode
    counts[b] = (counts[b] or 0) + 1
    if b ~= "normal" then list[#list + 1] = i .. ":" .. tostring(b) end
  end
  local s = {}
  for k, v in pairs(counts) do s[#s + 1] = k .. "=" .. v end
  table.sort(s)
  return table.concat(s, " "), table.concat(list, " ")
end

-- (0) the engine semantic the finding rests on: does `fill = {...}` reset blendMode on a real object?
do
  local tex = graphics.newTexture({ type = "image", filename = "spines/snowglobe/snowglobe.png" })
  local r = display.newRect(100, 100, 50, 50)
  r.blendMode = "multiply"
  local before = r.blendMode
  r.fill = { type = "image", filename = tex.filename, baseDir = tex.baseDir }
  L.log("(0) rect: blendMode before fill=", before, "after fill = {type='image',...}:", r.blendMode)
  r.blendMode = "add"; r:setFillColor(1, 0, 0)
  r.fill = { type = "image", filename = tex.filename, baseDir = tex.baseDir }
  L.log("(0) rect: after blend=add + setFillColor(1,0,0) then fill=: blendMode", r.blendMode, "fill.r", r.fill and r.fill.r)
  r:removeSelf(); tex:releaseSelf()
end

-- page-1 region names (snowglobe.png)
local ONPAGE1 = {}
do
  local page
  for line in io.lines(system.pathForFile("spines/snowglobe/snowglobe.atlas")) do
    if line:match("%.png$") then page = line
    elseif line:match("^[^%s]") and not line:find(":") and page == "snowglobe.png" then ONPAGE1[line] = true end
  end
end

local atlas = spine.loadAtlas("spines/snowglobe/snowglobe.atlas")
local data = spine.loadSkeletonData("spines/snowglobe/snowglobe.skel", atlas, 0.3)
local function make(x)
  local obj = spine.create(data)
  obj.x, obj.y = x, 700
  obj:setAnimation(1, "idle", true)
  obj:updateState(16); obj:draw(); obj:updateState(16); obj:draw()
  return obj
end
local function donorFor(obj)
  for _, s in ipairs(obj.slots) do
    local a = s.attachment
    if a and a.type == "region" and s.name ~= "globe-shadow" and ONPAGE1[a.name] then return a end
  end
end

-- (1) reused mesh: swap globe-shadow (multiply) to a region on page 1
local obj = make(200)
local shadow = obj:getSlot("globe-shadow")
L.log("(1) globe-shadow slot blendMode", shadow.blendMode, "attachment", shadow.attachment and shadow.attachment.name, "on page1?", shadow.attachment and ONPAGE1[shadow.attachment.name] or false)
local c1, l1 = blendSummary(obj)
L.log("(1) before swap: meshes", #children(obj), "blend counts", c1, "non-normal", l1)
local donor = donorFor(obj)
shadow.attachment = donor
obj:updateState(16); obj:draw()
local c2, l2 = blendSummary(obj)
L.log("(1) after swap to", donor and donor.name, ": meshes", #children(obj), "blend counts", c2, "non-normal", l2)
obj:updateState(16); obj:draw()
local c3, l3 = blendSummary(obj)
L.log("(1) one more frame: blend counts", c3, "non-normal", l3)

-- (2) control: fresh object with the swap applied before its first draw (new meshes)
local obj2 = spine.create(data)
obj2.x, obj2.y = 550, 700
obj2:setAnimation(1, "idle", true)
obj2:getSlot("globe-shadow").attachment = donorFor(obj2)
obj2:updateState(16); obj2:updateState(16); obj2:draw()
local c4, l4 = blendSummary(obj2)
L.log("(2) control (swap before first draw): blend counts", c4, "non-normal", l4)
timer.performWithDelay(100, function() L.finish(0) end)
