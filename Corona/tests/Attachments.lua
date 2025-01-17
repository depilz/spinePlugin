local text = display.newText("Drag me!", display.contentCenterX, display.screenOriginY + 50, native.systemFont, 24)

-- _G.allSpines = {"alien", "celestial-circus", "cloud-pot", "coin", "goblins", "hero", "mix-and-match", "owl", "powerup", "raptor", "sack", "speedy", "spineboy", "stretchyman",  "vine", "tank", "windmill" }
-- local atlas = Spine.getAtlasData("celestial-circus")
-- local skeleton = Spine.getSkeletonData("celestial-circus", atlas)
local atlas = Spine.getAtlasData(allSpines[8])
local skeleton = Spine.getSkeletonData(allSpines[8], atlas, 1)

local parent = display.newGroup()
local o = Spine.create(parent, skeleton, display.contentCenterX, display.contentCenterY+100)
local animations = o:getAnimations()
o:setAnimation(1, animations[1], true)
o:setSkin(o:getSkins()[3])

timer.performWithDelay(1, function()
    for i, slot in ipairs(o.slots) do
        local attachments = slot:getSkinAttachments("goblin")
        for j, attachment in ipairs(attachments) do
            if i % 2 == 0 then
                slot.attachment = slot.attachment:gsub(".*/", "goblin/")
            end
        end
    end
end)