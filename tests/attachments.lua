local fixture = require("attachment_fixture")
local function fails(fn)
    local ok = pcall(fn)
    assert(not ok, "Expected a Lua error")
end
local function gc() collectgarbage("collect"); collectgarbage("collect") end
local skeleton = fixture.new()
local slot = skeleton:getSlot("medal")
local empty = skeleton:getSlot("empty")
assert(skeleton:getSkin() == nil)
assert(slot.attachment.name == "art/base")
assert(#slot:getSkinAttachments() == 4)
assert(#slot:getSkinAttachments(nil) == 4)
assert(#empty:getSkinAttachments() == 0)
skeleton:setAttachment("medal", "fallback")
assert(slot.attachment.name == "art/fallback")
skeleton:setAttachment("medal", nil)
assert(slot.attachment == nil)
slot.attachment = "medal"
assert(slot.attachment.name == "art/base")

skeleton:setSkin("gold")
assert(slot.attachment.name == "art/gold")
assert(#slot:getSkinAttachments() == 1)
assert(slot:getSkinAttachments("missing") == nil)
skeleton:setAttachment("medal", "fallback")
assert(slot.attachment.name == "art/fallback")
slot.attachment = "fallback"
assert(slot.attachment.name == "art/fallback")
fails(function() slot.attachment = "art/gold" end)
fails(function() skeleton:setAttachment("medal", "art/gold") end)
assert(slot.attachment.name == "art/fallback")
skeleton:setAttachment("medal", "null")
assert(slot.attachment.name == "art/null")

local entries = slot:getAttachmentEntries()
local found = {}
for _, entry in ipairs(entries) do
    assert(entry.slotIndex == 0 and not found[entry.name])
    found[entry.name] = entry
    slot.attachment = entry.name
    assert(slot.attachment.name == entry.attachment.name)
end
assert(#entries == 4 and found.medal.skinName == "gold")
assert(found.fallback.skinName == "default")
assert(#slot:getAttachmentEntries("gold") == 1)
assert(slot:getAttachmentEntries("missing") == nil)
assert(#empty:getAttachmentEntries() == 0)

slot.attachment = nil
skeleton:setSkin("gold", false)
assert(slot.attachment == nil)
skeleton:setSkin("gold")
assert(slot.attachment.name == "art/gold")
fails(function() skeleton:setSkin("gold", "false") end)
assert(slot:setAttachmentFromSkin("default", "fallback"))
assert(skeleton:getSkin().name == "gold")
skeleton:setAnimation(1, "medal", true)
skeleton:updateState(10)
assert(slot.attachment.name == "art/gold")
slot.attachmentLocked = true
slot.attachment = nil
skeleton:updateState(10)
assert(slot.attachment == nil)
skeleton:setSkin("gold")
assert(slot.attachment.name == "art/gold") -- explicit reset overrides the lock
slot.attachmentLocked = false

-- Applied skins survive collection of their creating wrapper, including aliases.
do
    local custom = skeleton:createSkin("custom")
    assert(custom:addSkin("gold"))
    skeleton:setSkin(custom)
end
gc()
local alias = skeleton:getSkin()
assert(alias.name == "custom" and alias:getAttachment("medal", "medal").name == "art/gold")
skeleton:setSkin("gold")
gc()
assert(alias:getAttachment("medal", "medal").name == "art/gold")
skeleton:setSkin(alias)
alias = nil
gc()
assert(skeleton:getSkin().name == "custom")

local custom = skeleton:getSkin()
local attachment = custom:getAttachment("medal", "medal")
fails(function() custom:setAttachment("medal", "medal", "bad argument") end)
assert(custom:getAttachment("medal", "medal") ~= nil)
fails(function() custom:getAttachment(-1, "medal") end)
fails(function() custom:getAttachment(0.5, "medal") end)
fails(function() custom:getAttachment(2, "medal") end)
assert(custom:getAttachment(0, "medal").name == attachment.name)
custom:removeAttachment("medal", "medal")
assert(attachment.name == "art/gold")
assert(slot.attachment.name == "art/gold")
slot.attachment = attachment
attachment = nil
gc()
assert(slot.attachment.name == "art/gold")

-- Existing copying behavior is preserved; addSkin intentionally shares objects.
local peer = fixture.new(skeleton)
local copied = skeleton:createSkin("copied")
copied:copySkin("default")
local copiedAttachment = copied:getAttachment("medal", "medal")
copiedAttachment.color = {r = 0.25}
assert(peer:getSlot("medal").attachment.color.r == 1)
local shared = skeleton:createSkin("shared")
shared:addSkin("default")
shared:getAttachment("medal", "medal").color = {r = 0.5}
assert(peer:getSlot("medal").attachment.color.r == 0.5)
custom:setAttachment("medal", "copy", copiedAttachment)
custom:getAttachment("medal", "copy").color = {r = 0.75}
assert(copiedAttachment.color.r == 0.25)

-- Linked mesh parent and deform timeline survive source removal and GC.
local parentSkin = skeleton:createSkin("parent-mesh")
-- Select by key rather than relying on entry order.
for _, entry in ipairs(slot:getAttachmentEntries("default")) do
    if entry.name == "mesh" then parentSkin:setAttachment("medal", "mesh", entry.attachment) end
end
local linked = parentSkin:getAttachment("medal", "mesh")
local grandchild = skeleton:createSkin("grandchild")
grandchild:copySkin(parentSkin)
parentSkin:removeAttachment("medal", "mesh")
parentSkin = nil
copied = nil
linked = nil
gc()
local mesh = grandchild:getAttachment("medal", "mesh")
local another = skeleton:createSkin("another")
another:setAttachment("medal", "mesh", mesh)
mesh = nil
grandchild = nil
gc()
assert(another:getAttachment("medal", "mesh").type == "mesh")

local foreign = fixture.new()
fails(function() skeleton:setSkin(foreign:createSkin("foreign")) end)
fails(function() slot.attachment = foreign:getSlot("medal").attachment end)
fails(function() custom:addSkin(foreign:createSkin("foreign")) end)
fails(function() skeleton:registerSkin(foreign:createSkin("foreign")) end)
skeleton:registerSkin(custom)
skeleton:registerSkin(custom) -- same object registration is idempotent
fails(function() skeleton:registerSkin(skeleton:createSkin("custom")) end)
skeleton:setSkin("custom")

-- Retained wrappers keep their data alive, but removed slots reject access.
local retained = slot.attachment
local retainedName = retained.name
fixture.dispose(skeleton)
fails(function() return slot.attachment end)
assert(custom.name == "custom")
assert(retained.name == retainedName)
fixture.dispose(peer)
fixture.dispose(foreign)
gc()
print("Attachment binding regressions passed")
