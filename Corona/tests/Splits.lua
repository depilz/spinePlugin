-- _G.allSpines = {"alien", "celestial-circus", "cloud-pot", "coin", "goblins", "hero", "mix-and-match", "owl", "powerup", "raptor", "sack", "speedy", "spineboy", "stretchyman",  "vine", "tank", "windmill" }
-- local atlas = Spine.getAtlasData("celestial-circus")
-- local skeleton = Spine.getSkeletonData("celestial-circus", atlas)
local atlas = Spine.getAtlasData("raptor")
local skeleton = Spine.getSkeletonData("raptor", atlas, .3)

local parent = display.newGroup()
local o = Spine.create(parent, skeleton, display.contentCenterX, display.contentCenterY+100)
local animations = o:getAnimations()
o:setAnimation(1, animations[5], true)

local slots = {}
for i, slot in ipairs(o.slots) do
    if math.random() < .5 then
        table.insert(slots, slot.name)
    end
end

local group = o:split(slots)

group.x = display.contentCenterX + 50
group.y = display.contentCenterY + 50

local prevX, prevY
group.stage:addEventListener("touch", function(event)
    if event.phase == "began" then
        prevX, prevY = event.x, event.y
    elseif event.phase == "moved" then
        group.x = group.x + event.x - prevX
        group.y = group.y + event.y - prevY
        prevX, prevY = event.x, event.y
    else
        prevX, prevY = nil, nil
    end
end)

-- timer.performWithDelay(3000, function()
--     local slots = {}
--     for i, slot in ipairs(o.slots) do
--         if math.random() < .5 then
--             table.insert(slots, slot.name)
--         end
--     end
-- end, 0)

timer.performWithDelay(3000, function()
    -- o:removeSelf()
    -- o:reassemble()
end)