-- S3 (render-2): inject into the first-drawn slot, set that slot's attachment alpha to 0, draw() in pcall.
local L = require("simlib")
L.watchdogMs = 20000
L.open("s3_emptycmd " .. L.arg)
local CASES = { L.arg == "spineboy" and "spineboy" or "raptor" }
local SECOND_INJECT = L.arg == "second"
local spine = L.loadPlugin()
local gidx = getmetatable(display.newGroup()).__index -- Solar2D's group __index, to read real children
local function children(obj)
  local t = {}
  local n = gidx(obj, "numChildren")
  for i = 1, n do t[#t + 1] = gidx(obj, i) end
  return t
end
local function firstRegionSlot(obj)
  for _, name in ipairs(obj:getDrawOrder()) do
    local s = obj:getSlot(name)
    local a = s.attachment
    if a then return s, a end
  end
end
local x = 150
for _, name in ipairs(CASES) do
  local atlas = spine.loadAtlas(("spines/%s/%s.atlas"):format(name, name))
  local data = spine.loadSkeletonData(("spines/%s/%s.skel"):format(name, name), atlas, 0.3)
  local obj = spine.create(data)
  obj.x, obj.y = x, 700; x = x + 300
  obj:setAnimation(1, obj:getAnimations()[1], true)
  obj:updateState(16); obj:draw()
  local slot, att = firstRegionSlot(obj)
  L.log(name, "first drawn slot", slot.name, "attachment", att.name, att.type, "real children", #children(obj))
  local marker = display.newRect(0, 0, 10, 10)
  obj:inject(marker, slot.name)
  obj:updateState(16); obj:draw()
  L.log(name, "after inject: draw ok, real children", #children(obj))
  if SECOND_INJECT then
    local slot2 = obj:getDrawOrder()[8]
    obj:inject(display.newCircle(0, 0, 6), slot2)
    L.log(name, "second injection into later slot", slot2)
  end
  att.color = { a = 0 }
  L.log(name, "set attachment.color = {a=0}; calling draw() inside pcall ...")
  local ok, err = pcall(function() obj:updateState(16); obj:draw() end)
  L.log(name, "draw #1 ->", ok, err)
  ok, err = pcall(function() obj:updateState(16); obj:draw() end)
  L.log(name, "draw #2 ->", ok, err)
  local kids = children(obj)
  local kinds = {}
  for i, c in ipairs(kids) do kinds[#kinds + 1] = (c == marker) and "MARKER" or tostring(c.path and c.path.type or "?") end
  L.log(name, "real children after", #kids, table.concat(kinds, ","))
end
timer.performWithDelay(300, function() L.log("still alive after 300 ms"); L.finish(0) end)
