-- Data (SkeletonData-owned) skins are read-only: removing attachments from them while they are displayed / used as
-- linked-mesh parents raises instead of freeing what the animation still reads (the 4.3 DeformTimeline use-after-free).
local spine = require("plugin.spine")
local S = __stub
local atlas = spine.loadAtlas("goblins/goblins.atlas")
local data = spine.loadSkeletonData("goblins/goblins.json", atlas)
local a = spine.create(data)
local b = spine.create(data)
a:setSkin("goblin"); a:setSlotsToSetupPose(); a:setAnimation(1, "walk", true)
b:setSkin("goblingirl"); b:setSlotsToSetupPose(); b:setAnimation(1, "walk", true)
local function frames(n, ...) for _ = 1, n do for _, o in ipairs({ ... }) do o:updateState(33); o:draw() end end end
local function shown(o) return o:getSlot("head").attachment.name .. "," .. o:getSlot("left-foot").attachment.name end
frames(5, a, b)
local goblin = a:getSkin()
local headWrapper = a:getSlot("head").attachment
local before = { a = shown(a), b = shown(b) }
print("data skin:", goblin:getName(), "shown:", before.a, before.b)
-- goblin/left-foot is the parent + timelineAttachment of goblingirl/left-foot (linked mesh);
-- goblin/head is the deform-timeline target displayed by a
S.raises("read-only", goblin.removeAttachment, goblin, "left-foot", "left-foot")
S.raises("read-only", goblin.removeAttachment, goblin, "head", "head")
assert(goblin:getAttachment("left-foot", "left-foot") and goblin:getAttachment("head", "head"), "data skin was mutated")
local updates = S.meshUpdates
frames(5, a, b)   -- b still deforms via its parent
assert(S.meshUpdates > updates, "a/b stopped drawing")
assert(shown(a) == before.a and shown(b) == before.b, "shown attachments changed: " .. shown(a) .. " " .. shown(b))
a:setSkin("goblingirl"); a:setSlotsToSetupPose()
frames(5, a)
print("head wrapper still usable:", headWrapper.name)
headWrapper = nil; S.gcfull()
a:setSkin("goblin"); a:setSlotsToSetupPose()
frames(5, a)
assert(shown(a) == before.a, "goblin skin no longer shows " .. before.a)
a:removeSelf(); b:removeSelf(); S.frame(); goblin = nil; data = nil; atlas = nil
S.gcfull()
print("released textures:", S.texturesReleased, "of", S.texturesCreated)
assert(S.texturesCreated > 0 and S.texturesReleased == S.texturesCreated, "textures not released")
