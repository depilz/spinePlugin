-- T22 (4.3 only): attachment.region, attachment:copy{ region } and skeleton:createAttachment (I14 D17, A4), in the
-- ASan+UBSan host. Regions come from the skeleton's own atlas (spineboy.atlas, diamond.atlas, chibi-stickers.atlas).
-- mode = read | copy | create | dispose | outlive | cross
--   read     region/mesh attachments read their setup region's table; bounding box, clipping and point read nil; a
--            write raises the copy hint
--   copy     copy{ region } retargets the copy only (region and mesh); plain copy() keeps the region; a miss, a
--            multi-frame sequence, another attachment type and a non-table argument raise and copy nothing
--   create   createAttachment makes a region attachment of the region's original size (or the given geometry) that
--            the skeleton draws; bad arguments raise
--   dispose  copies and created attachments on a custom skin and a slot, then the skeleton removed and everything
--            collected
--   outlive  a remapped mesh copy on another skeleton follows the original's deform timeline (hoverboard), outlives
--            that skeleton and is drawn on a third one
--   cross    a copy and a created attachment on another skeleton's custom skin, drawn and updated after their source
--            skeleton, SkeletonData and Atlas were released and collectgarbage ran
local spine = require("plugin.spine")
local S = __stub
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local mode = arg[1]
local HINT = "SpineAttachment: property 'region' is read-only; use attachment:copy{ region = … }"
local MISS = "Region not found in the skeleton's atlas: "

local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)

-- raises(f, message): f raised an error ending in message
local function raises(f, message)
  local ok, err = pcall(f)
  print("  raised:", not ok, err)
  return not ok and tostring(err):sub(-#message) == message
end
-- regionIs(attachment, fields): attachment.region has every field of fields
local function regionIs(attachment, fields)
  local region = attachment.region
  if not region then print("  region: nil") return false end
  local line = {}
  for k, v in pairs(region) do line[#line + 1] = k .. "=" .. tostring(v) end
  table.sort(line)
  print("  region:", table.concat(line, " "))
  for k, v in pairs(fields) do
    if region[k] ~= v then return false end
  end
  return true
end
local function same(a, b)
  if #a ~= #b or #a == 0 then return false end
  for i = 1, #a do if math.abs(a[i] - b[i]) > 1e-3 then return false end end
  return true
end
-- frames(n, ...): each object updated 33 ms and drawn, n times
local function frames(n, ...)
  for _ = 1, n do for _, o in ipairs({ ... }) do o:updateState(33); o:draw() end end
end
-- release(...): the objects removed and the removal frame run
local function release(...)
  for _, o in ipairs({ ... }) do o:removeSelf() end
  S.frame()
end

if mode == "read" then
  local s = spine.create(data)
  local default = s:findSkin("default")
  local crosshair = default:getAttachment("crosshair", "crosshair")
  C.expect(regionIs(crosshair, { name = "crosshair", x = 186, y = 17, width = 45, height = 45, originalWidth = 45,
    originalHeight = 45, offsetX = 0, offsetY = 0, rotated = false, degrees = 0, baseDir = "ResourceDirectory" }),
    "the region attachment's region table")
  C.expect(tostring(crosshair.region.filename):match("spineboy%.png$"), "filename is not the page texture's")
  C.expect(regionIs(default:getAttachment("head", "head"), { name = "head", x = 29, y = 76 }), "the mesh's region")
  C.expect(default:getAttachment("head-bb", "head").type == "boundingbox" and
    default:getAttachment("head-bb", "head").region == nil, "a bounding box reads a region")
  C.expect(default:getAttachment("clipping", "clipping").region == nil, "a clipping attachment reads a region")
  local rig = spine.create(spine.loadSkeletonData(arg[0]:match("^(.*)/") .. "/assets/4.3/slider-attachment.json", atlas))
  C.expect(rig:getSlot("marker").attachment.type == "point" and rig:getSlot("marker").attachment.region == nil,
    "a point attachment reads a region")
  -- a trimmed region rotated 180 (offsets) and a region rotated 90 (packed size as it lies on the page)
  local diamond = spine.create(spine.loadSkeletonData("diamond/diamond.json", spine.loadAtlas("diamond/diamond.atlas")))
  C.expect(regionIs(diamond:createAttachment({ region = "lower-side-2", name = "d" }), { x = 851, y = 55, width = 77,
    height = 78, originalWidth = 78, originalHeight = 79, offsetX = 0, offsetY = 0, rotated = false, degrees = 180 }),
    "the trimmed, 180-rotated region's table")
  local chibi = spine.create(spine.loadSkeletonData("chibi-stickers/chibi-stickers.json",
    spine.loadAtlas("chibi-stickers/chibi-stickers.atlas")))
  C.expect(regionIs(chibi:createAttachment({ region = "erikari/back-hair-long", name = "c" }), { x = 257, y = 198,
    width = 254, height = 220, rotated = true, degrees = 90 }), "the 90-rotated region's table")
  C.expect(raises(function() crosshair.region = "goggles" end, HINT), "a region write did not raise the hint")
  C.expect(raises(function() crosshair.region = nil end, HINT), "a nil region write did not raise the hint")
  C.expect(crosshair.region.name == "crosshair", "a raised write changed the region")
  release(s, rig, diamond, chibi)
elseif mode == "copy" then
  local s = spine.create(data)
  local default = s:findSkin("default")
  local bracer = default:getAttachment("front-bracer", "front-bracer")
  local copy = bracer:copy({ region = "crosshair" })
  C.expect(copy ~= bracer and copy.type == "region" and copy.name == "front-bracer", "the copy's identity")
  C.expect(regionIs(copy, { name = "crosshair" }) and regionIs(bracer, { name = "front-bracer" }),
    "copy{ region } did not retarget the copy only")
  C.expect(copy.width == bracer.width and copy.height == bracer.height, "the copy's size changed")
  C.expect(regionIs(bracer:copy(), { name = "front-bracer" }), "plain copy() changed the region")
  local head = default:getAttachment("head", "head")
  C.expect(regionIs(head:copy({ region = "goggles" }), { name = "goggles" }) and regionIs(head, { name = "head" }),
    "a mesh copy{ region } did not retarget the copy only")
  C.expect(raises(function() bracer:copy({ region = "no-such-region" }) end, MISS .. "no-such-region"),
    "a missing region did not raise")
  C.expect(raises(function() bracer:copy({}) end, "region (an atlas region name) expected"), "no region field")
  C.expect(raises(function() bracer:copy("crosshair") end, "(table expected, got string)"), "a string argument")
  C.expect(raises(function() default:getAttachment("head-bb", "head"):copy({ region = "crosshair" }) end,
    "SpineAttachment: copy{ region } needs a region or mesh attachment, not a boundingbox attachment"),
    "a bounding box copy{ region } did not raise")
  local diamond = spine.create(spine.loadSkeletonData("diamond/diamond.json", spine.loadAtlas("diamond/diamond.atlas")))
  local top = diamond:findSkin("default"):getAttachment("top-shine", "top")
  local frame = top.region.name
  C.expect(raises(function() top:copy({ region = "top" }) end,
    "SpineAttachment: copy{ region } needs a single-frame attachment; 'top' has a 7-frame sequence"),
    "a multi-frame sequence did not raise")
  C.expect(regionIs(top, { name = frame }), "a raised copy changed the multi-frame attachment")
  C.expect(regionIs(bracer, { name = "front-bracer" }), "a raised copy changed the original")
  release(s, diamond)
elseif mode == "create" then
  local s = spine.create(data)
  local made = s:createAttachment({ region = "crosshair", name = "made" })
  C.expect(made.type == "region" and made.name == "made" and made.path == "crosshair", "the created identity")
  C.expect(made.width == 45 and made.height == 45 and made.x == 0 and made.scaleX == 1, "the created defaults")
  C.expect(regionIs(made, { name = "crosshair" }), "the created region")
  local placed = s:createAttachment({ region = "crosshair", name = "placed", width = 90, height = 20, x = 5, y = 6,
    rotation = 30, scaleX = 2, scaleY = 3 })
  C.expect(placed.width == 90 and placed.height == 20 and placed.x == 5 and placed.y == 6 and placed.rotation == 30
    and placed.scaleX == 2 and placed.scaleY == 3, "the given geometry")
  local slot = s:getSlot("front-bracer")
  slot.attachment = made
  frames(2, s)
  C.expect(slot.attachment == made and #made:computeWorldVertices(slot) == 8, "the slot does not show the created one")
  C.expect(raises(function() s:createAttachment({ region = "no-such-region", name = "x" }) end, MISS .. "no-such-region"),
    "a missing region did not raise")
  C.expect(raises(function() s:createAttachment({ name = "x" }) end, "region (an atlas region name) expected"),
    "no region")
  C.expect(raises(function() s:createAttachment({ region = "crosshair" }) end,
    "createAttachment: name (a non-empty string) expected"), "no name")
  C.expect(raises(function() s:createAttachment({ region = "crosshair", name = "" }) end,
    "createAttachment: name (a non-empty string) expected"), "an empty name")
  C.expect(raises(function() s:createAttachment({ region = "crosshair", name = "x", width = "wide" }) end,
    "createAttachment: width must be a number"), "a non-number width")
  C.expect(raises(function() s:createAttachment("crosshair") end, "(table expected, got string)"), "a string argument")
  local create = s.createAttachment -- a removed skeleton's methods are gone: only a cached one still reaches it
  release(s)
  C.expect(raises(function() create(s, { region = "crosshair", name = "late" }) end,
    "Skeleton belongs to a removed skeleton"), "a removed skeleton created an attachment")
elseif mode == "dispose" then
  for _ = 1, 20 do
    local s = spine.create(data)
    local skin = s:createSkin("remapped")
    skin:setAttachment("front-bracer", "front-bracer", s:getSlot("front-bracer").attachment:copy({ region = "crosshair" }))
    skin:setAttachment("gun", "gun", s:createAttachment({ region = "goggles", name = "gun" }))
    s:setSkin(skin); s:setSlotsToSetupPose()
    s:getSlot("head").attachment = s:getSlot("head").attachment:copy({ region = "eye-surprised" })
    s:setAnimation(1, "walk", true)
    frames(3, s)
    C.expect(s:getSlot("gun").attachment.region.name == "goggles", "the created attachment is not shown")
    s:createAttachment({ region = "crosshair", name = "dropped" }):copy({ region = "goggles" })
    skin = nil; S.gcfull()
    frames(2, s)
    release(s); S.gcfull()
  end
  data, atlas = nil, nil; S.gcfull()
  C.expect(S.texturesCreated > 0 and S.texturesReleased == S.texturesCreated, "textures not released")
elseif mode == "outlive" then
  local a, b = spine.create(data), spine.create(data)
  local foot = a:getSlot("front-foot").attachment
  local copy = foot:copy({ region = "rear-foot" })
  local skin = b:createSkin("remapped")
  skin:setAttachment("front-foot", "front-foot", copy)
  b:setSkin(skin); b:setSlotsToSetupPose()
  C.expect(b:getSlot("front-foot").attachment == copy, "b does not show the copy")
  a:setAnimation(1, "hoverboard", true); b:setAnimation(1, "hoverboard", true)
  frames(12, a, b)
  -- same bones, same deform: the original's deform timeline drives the copy (its world vertices do not use the region)
  local original, copied = foot:computeWorldVertices(a:getSlot("front-foot")), copy:computeWorldVertices(b:getSlot("front-foot"))
  C.expect(same(original, copied), "the copy does not follow the original's deform timeline")
  release(b); skin = nil; S.gcfull()
  C.expect(copy.region.name == "rear-foot" and copy.name == "front-foot", "the copy did not outlive its skeleton")
  local c = spine.create(data)
  c:getSlot("front-foot").attachment = copy
  a:setAnimation(1, "hoverboard", true); c:setAnimation(1, "hoverboard", true)
  local updates = S.meshUpdates
  frames(12, a, c)
  C.expect(S.meshUpdates > updates, "c stopped drawing")
  C.expect(same(foot:computeWorldVertices(a:getSlot("front-foot")), copy:computeWorldVertices(c:getSlot("front-foot"))),
    "the outliving copy does not follow the original's deform timeline")
  release(a, c); copy, foot = nil, nil
  data, atlas = nil, nil; S.gcfull()
  C.expect(S.texturesCreated > 0 and S.texturesReleased == S.texturesCreated, "textures not released")
elseif mode == "cross" then
  local a, b = spine.create(data), spine.create(data)
  local skin = b:createSkin("remapped")
  skin:setAttachment("front-bracer", "front-bracer", a:getSlot("front-bracer").attachment:copy({ region = "crosshair" }))
  skin:setAttachment("front-foot", "front-foot", a:getSlot("front-foot").attachment:copy({ region = "rear-foot" }))
  skin:setAttachment("gun", "gun", a:createAttachment({ region = "goggles", name = "gun" }))
  b:setSkin(skin); b:setSlotsToSetupPose()
  -- the source skeleton, SkeletonData and Atlas released and collected: only b keeps them
  release(a); a, skin, data, atlas = nil, nil, nil, nil
  S.gcfull()
  local released = S.texturesReleased
  b:setAnimation(1, "hoverboard", true)
  local updates = S.meshUpdates
  frames(20, b)
  C.expect(S.meshUpdates > updates, "b stopped drawing")
  C.expect(b:getSlot("front-bracer").attachment.region.name == "crosshair" and
    b:getSlot("gun").attachment.region.name == "goggles" and b:getSlot("front-foot").attachment.region.name == "rear-foot",
    "b does not show the copies")
  C.expect(S.texturesReleased == released, "a texture was released while b draws it")
  release(b); b = nil; S.gcfull()
  C.expect(S.texturesCreated > 0 and S.texturesReleased == S.texturesCreated, "textures not released")
end
print("end of script")
C.done()
