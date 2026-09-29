-- slot.darkColor is read-only: a dark slot reads a fresh {r, g, b} (0..1) of its float dark colour, a slot without one
-- reads nil. On the tint-black fixture (tests/sim/assets/tintblack):
--   values     every slot's setup dark colour; nodark is nil, darkblack a black table, not nil
--   pulse      follows the `pulse` rgba2 keys (ff0000 -> 0000ff -> 000000, linear) frame by frame
--   usereffect keeps reporting while the skeleton has a user fill effect, across draws
--   readonly   a write raises the read-only error and leaves the dark colour as it was
--   removed    a read and a write on a removed skeleton's slot raise, in the dispose window and after the next frame
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1]
local dir = arg[0]:match("^(.*)/") .. "/../sim/assets/tintblack/" .. os.getenv("SPINE_RUNTIME") .. "/"
local atlas = spine.loadAtlas(dir .. "tintblack.atlas")
local data = spine.loadSkeletonData(dir .. "tintblack.json", atlas)
local obj = spine.create(data)

-- the fixture's setup dark colours (generate.py SLOTS), nil = no dark colour
local setup = {
  normal = "3399ff", pulse = "ff0000", additive = "3399ff", alpha = "808080", multiply = "3399ff", screen = "3399ff",
  darkblack = "000000", nodark = nil, lightblack = "7e7e7e", swap = "3399ff",
}
local names = { "normal", "pulse", "additive", "alpha", "multiply", "screen", "darkblack", "nodark", "lightblack", "swap" }

local function near(a, b) return math.abs(a - b) < 1e-4 end
local function expectDark(slot, r, g, b, what)
  local dark = slot.darkColor
  assert(type(dark) == "table", what .. ": expected a table, got " .. tostring(dark))
  assert(near(dark.r, r) and near(dark.g, g) and near(dark.b, b) and dark.a == nil,
    string.format("%s: expected %.4f %.4f %.4f, got %s %s %s a=%s", what, r, g, b, tostring(dark.r), tostring(dark.g),
      tostring(dark.b), tostring(dark.a)))
end
local function hex(h, i) return tonumber(h:sub(i, i + 1), 16) / 255 end

-- the pulse slot's dark colour at animation time t (s): red -> blue over [0, 1], blue -> black over [1, 2]
local function pulseAt(t)
  if t <= 1 then return 1 - t, 0, t end
  return 0, 0, math.max(0, 2 - t)
end

if mode == "values" then
  for _, name in ipairs(names) do
    local slot = obj:getSlot(name)
    local h = setup[name]
    if h then expectDark(slot, hex(h, 1), hex(h, 3), hex(h, 5), name)
    else assert(slot.darkColor == nil, name .. ": expected nil, got " .. tostring(slot.darkColor)) end
    print(name, h or "nil")
  end
  -- every read is a new table; editing it does not reach the slot
  local slot = obj:getSlot("normal")
  local first = slot.darkColor
  assert(first ~= slot.darkColor, "each read must build a new table")
  first.r = 0
  expectDark(slot, hex("3399ff", 1), hex("3399ff", 3), hex("3399ff", 5), "normal after editing a read")
elseif mode == "pulse" or mode == "usereffect" then
  local slot = obj:getSlot("pulse")
  if mode == "usereffect" then
    obj.fill.effect = "filter.desaturate"
    assert(obj.fill.effect ~= nil, "the user effect must be set")
  end
  obj:setAnimation(1, "pulse", false)
  local step, t = 50, 0
  obj:updateState(0)
  while t <= 2.2 do
    local r, g, b = pulseAt(t)
    expectDark(slot, r, g, b, string.format("pulse t=%.2f", t))
    if mode == "usereffect" then
      obj:draw()
      expectDark(slot, r, g, b, string.format("pulse t=%.2f after draw", t))
    end
    obj:updateState(step); t = t + step / 1000
  end
  print(mode, "frames checked through t=2.2")
elseif mode == "readonly" then
  local slot = obj:getSlot("normal")
  local message = "SpineSlot: property 'darkColor' is read-only"
  for _, value in ipairs({ { r = 1, g = 0, b = 0 }, false, "x" }) do
    S.raises(message, function() slot.darkColor = value end)
    expectDark(slot, hex("3399ff", 1), hex("3399ff", 3), hex("3399ff", 5), "normal after a rejected write")
  end
  -- a slot without a dark colour raises the same and stays nil
  local nodark = obj:getSlot("nodark")
  S.raises(message, function() nodark.darkColor = { r = 1, g = 1, b = 1 } end)
  assert(nodark.darkColor == nil, "nodark must stay nil")
elseif mode == "removed" then
  local slot = obj:getSlot("normal")
  local dead = "Slot belongs to a removed skeleton"
  obj:removeSelf(); S.endFrame()                -- the dispose window: finalized, the next frame has not begun
  S.raises(dead, function() return slot.darkColor end)
  S.raises(dead, function() slot.darkColor = { r = 0, g = 0, b = 0 } end)
  S.frame(); S.gcfull()                         -- after the next-frame hook and a full GC
  S.raises(dead, function() return slot.darkColor end)
  S.raises(dead, function() slot.darkColor = { r = 0, g = 0, b = 0 } end)
else
  error("unknown mode " .. tostring(mode))
end
print("survived")
