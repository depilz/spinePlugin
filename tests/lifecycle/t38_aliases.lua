-- Naming aliases: each alias reads and writes the same value as its canonical key, keeps the canonical key's type
-- gating, and raises with the key the user typed.
--   bone        scaleX/scaleY (canonical) and xScale/yScale
--   attachment  scaleX/scaleY and xScale/yScale (region only), r/g/b/a and color (every type with a colour)
--   slot        a and alpha
--   fill        color and r/g/b/a
--   entry       trackIndex and index, both read-only
--   event       loop and looping on every phase but "event", neither on "event"
--   ik          getIkConstraint/getIkConstraintNames and getIKConstraint/getIKConstraintNames
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1]
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj = spine.create(data)

-- expectSame(o, canonical, alias, values): both keys read equal, and a write through either reads back through
-- the other
local function expectSame(o, canonical, alias, values)
  local function readsBack(written, read, value)
    o[written] = value
    assert(o[read] == value, ("%s = %s read back %s through %s"):format(written, value, tostring(o[read]), read))
  end
  assert(o[canonical] == o[alias],
    ("%s %s ~= %s %s"):format(canonical, tostring(o[canonical]), alias, tostring(o[alias])))
  readsBack(alias, canonical, values[1])
  readsBack(canonical, alias, values[2])
  print(canonical, alias, "ok")
end

-- expectColor(o, r, g, b, a): o's r/g/b/a components and its color table hold r, g, b, a
local function expectColor(o, r, g, b, a)
  local color = o.color
  for key, want in pairs({ r = r, g = g, b = b, a = a }) do
    assert(o[key] == want, ("%s is %s, expected %s"):format(key, tostring(o[key]), want))
    assert(color[key] == want, ("color.%s is %s, expected %s"):format(key, tostring(color[key]), want))
  end
end

if mode == "bone" then
  local bone = obj.bones[3]
  expectSame(bone, "scaleX", "xScale", { 0.5, 2 })
  expectSame(bone, "scaleY", "yScale", { 0.25, 3 })
elseif mode == "attachment" then
  local region = obj:getSlot("front-fist").attachment
  assert(region.type == "region", "front-fist must hold a region attachment: the test proves nothing")
  expectSame(region, "scaleX", "xScale", { 0.5, 2 })
  expectSame(region, "scaleY", "yScale", { 0.25, 3 })
  for _, key in ipairs({ "r", "g", "b", "a" }) do
    region[key] = 0.5
    assert(region.color[key] == 0.5, key .. " did not reach color")
  end
  region.color = { r = 0.25, g = 0.5, b = 0.75, a = 1 }
  expectColor(region, 0.25, 0.5, 0.75, 1)

  local mesh = obj:getSlot("head").attachment
  assert(mesh.type == "mesh", "head must hold a mesh attachment: the test proves nothing")
  assert(mesh.xScale == nil and mesh.scaleX == nil, "a mesh attachment reads a scale")
  S.raises("SpineAttachment: unknown property 'xScale' on a mesh attachment", function() mesh.xScale = 1 end)
  S.raises("SpineAttachment: unknown property 'yScale' on a mesh attachment", function() mesh.yScale = 1 end)
  mesh.color = { r = 1, g = 0.5, b = 0.25, a = 0.5 }
  expectColor(mesh, 1, 0.5, 0.25, 0.5)
  mesh.g = 0.75
  expectColor(mesh, 1, 0.75, 0.25, 0.5)

  local bbSlot = obj:getSlot("head-bb")
  bbSlot.attachment = "head"
  local bb = bbSlot.attachment
  assert(bb.type == "boundingbox", "head-bb must hold a boundingbox attachment: the test proves nothing")
  bb.a = 0.5
  expectColor(bb, bb.color.r, bb.color.g, bb.color.b, 0.5)
  S.raises("SpineAttachment: unknown property 'xScale' on a boundingbox attachment", function() bb.xScale = 1 end)
  S.raises("SpineAttachment: unknown property 'scaleX' on a boundingbox attachment", function() bb.scaleX = 1 end)
elseif mode == "slot" then
  local slot = obj:getSlot("head")
  expectSame(slot, "a", "alpha", { 0.5, 0.25 })
  assert(slot.color.a == 0.25, "slot.a is not color.a")
  slot.color = { a = 0.75 }
  assert(slot.a == 0.75 and slot.alpha == 0.75, "a color write did not reach a and alpha")
elseif mode == "fill" then
  local fill = obj.fill
  expectColor(fill, 1, 1, 1, 1)
  fill.color = { r = 0.25, g = 0.5, b = 0.75, a = 0.5 }
  expectColor(fill, 0.25, 0.5, 0.75, 0.5)
  fill.color = { g = 1 }
  expectColor(fill, 0.25, 1, 0.75, 0.5)
  fill.r = 0.5
  assert(fill.color.r == 0.5, "fill.r did not reach fill.color")
  obj:setFillColor(0, 0, 0, 1)
  expectColor(fill, 0, 0, 0, 1)
  local read = fill.color
  read.r = 1
  assert(fill.r == 0, "editing a fill.color read reached the fill")
  S.raises("table expected", function() fill.color = 1 end)
elseif mode == "entry" then
  obj:setAnimation(2, "walk", true)
  local e = obj:getTrackEntry(2)
  assert(e.trackIndex == 2 and e.index == 2,
    ("trackIndex %s, index %s, expected 2"):format(tostring(e.trackIndex), tostring(e.index)))
  S.raises("SpineTrackEntry: property 'trackIndex' is read-only", function() e.trackIndex = 3 end)
  S.raises("SpineTrackEntry: property 'index' is read-only", function() e.index = 3 end)
  assert(e.trackIndex == 2, "a rejected trackIndex write changed the entry")
elseif mode == "event" then
  local events = spine.loadSkeletonData(arg[0]:match("^(.*)/") .. "/../animation/assets/" .. os.getenv("SPINE_RUNTIME")
    .. "/spineboy-events.json", atlas)
  -- the listener records instead of asserting: a listener error is reported and the plugin call carries on
  local seen, wrong = {}, {}
  local s = spine.create(events, function(ev)
    seen[ev.phase] = (seen[ev.phase] or 0) + 1
    local ok = ev.phase == "event" and ev.loop == nil and ev.looping == nil
      or ev.phase ~= "event" and type(ev.looping) == "boolean" and ev.loop == ev.looping
    if not ok then
      wrong[#wrong + 1] = ("%s: loop %s, looping %s"):format(ev.phase, tostring(ev.loop), tostring(ev.looping))
    end
  end)
  s:setDefaultMix(200)
  s:setAnimation(1, "walk", true)
  for i = 1, 11 do s:updateState(100) end
  s:setAnimation(1, "jump", false)
  for i = 1, 20 do s:updateState(100) end
  for _, phase in ipairs({ "began", "completed", "interrupted", "ended", "disposed", "event" }) do
    print(phase, seen[phase])
    assert(seen[phase], "no '" .. phase .. "' event: the test proves nothing")
  end
  assert(#wrong == 0, table.concat(wrong, "; "))
elseif mode == "ik" then
  local ik, IK = obj:getIkConstraint("aim-ik"), obj:getIKConstraint("aim-ik")
  assert(ik.name == "aim-ik" and IK.name == "aim-ik", "getIkConstraint and getIKConstraint disagree")
  local names, NAMES = obj:getIkConstraintNames(), obj:getIKConstraintNames()
  assert(#names > 0 and #names == #NAMES, "getIkConstraintNames and getIKConstraintNames differ in length")
  for i, name in ipairs(names) do assert(NAMES[i] == name, "names differ at " .. i) end
  S.raises("IKConstraint not found: nope", function() obj:getIkConstraint("nope") end)
else
  error("unknown mode " .. tostring(mode))
end
print("survived")
