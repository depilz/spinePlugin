-- T21 (4.3 only): slot.appliedAttachment, the applied pose's attachment the renderer draws (I14 D15).
-- tests/animation/assets/4.3/slider-attachment.json: slot "marker" shows "setup"; the slider "swap" (no bone, time 0)
-- applies "swap", which keys "marker" to "keyed" in the applied pose only.
-- mode = applied | readonly
--   applied   slot.attachment reads the pose ("setup", then nil once cleared); appliedAttachment reads "keyed"
--   readonly  writing appliedAttachment raises the D15 hint and changes neither key; on a removed skeleton's slot
--             the lifecycle error comes first
local spine = require("plugin.spine")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local W = arg[0]:match("^(.*)/")
local mode = arg[1]
local data = spine.loadSkeletonData(W .. "/assets/4.3/slider-attachment.json", spine.loadAtlas("spineboy/spineboy.atlas"))
local s = spine.create(data)
local slot = s:getSlot("marker")
local READONLY = "SpineSlot: property 'appliedAttachment' is read-only; it is the attachment the renderer draws — set slot.attachment"

-- raises(f, message): f raised an error ending in message
local function raises(f, message)
  local ok, err = pcall(f)
  print("  raised:", not ok, err)
  return not ok and tostring(err):sub(-#message) == message
end
-- name(attachment): its name, or nil
local function name(attachment) return attachment and attachment.name end
-- keys(): prints and returns slot.attachment's and slot.appliedAttachment's names
local function keys()
  local pose, applied = name(slot.attachment), name(slot.appliedAttachment)
  print("  attachment:", pose, "appliedAttachment:", applied)
  return pose, applied
end

if mode == "applied" then
  local pose, applied = keys()
  C.expect(pose == "setup" and applied == "keyed", "after create the slider's key did not reach appliedAttachment")
  s:updateState(16)
  pose, applied = keys()
  C.expect(pose == "setup" and applied == "keyed", "after an update the slider's key did not reach appliedAttachment")
  slot.attachment = nil
  s:updateState(16)
  pose, applied = keys()
  C.expect(pose == nil and applied == "keyed", "clearing slot.attachment changed what the slider keys")
elseif mode == "readonly" then
  C.expect(raises(function() slot.appliedAttachment = "setup" end, READONLY), "a name write did not raise the hint")
  C.expect(raises(function() slot.appliedAttachment = nil end, READONLY), "a nil write did not raise the hint")
  local pose, applied = keys()
  C.expect(pose == "setup" and applied == "keyed", "a raised write changed the slot")
  s:removeSelf(); __stub.frame()
  C.expect(raises(function() return slot.appliedAttachment end, "Slot belongs to a removed skeleton"),
    "a removed skeleton's slot did not raise the lifecycle error on read")
  C.expect(raises(function() slot.appliedAttachment = nil end, "Slot belongs to a removed skeleton"),
    "a removed skeleton's slot did not raise the lifecycle error on write")
end
print("end of script")
C.done()
