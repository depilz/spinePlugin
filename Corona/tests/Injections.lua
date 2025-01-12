-- _G.allSpines = {"alien", "celestial-circus", "cloud-pot", "coin", "goblins", "hero", "mix-and-match", "owl", "powerup", "raptor", "sack", "speedy", "spineboy", "stretchyman",  "vine", "tank", "windmill" }
-- local atlas = Spine.getAtlasData("celestial-circus")
-- local skeleton = Spine.getSkeletonData("celestial-circus", atlas)
local atlas = Spine.getAtlasData("raptor")
local skeleton = Spine.getSkeletonData("raptor", atlas, .3)

local parent = display.newGroup()
local o = Spine.create(parent, skeleton, display.contentCenterX, display.contentCenterY+100)
local animations = o:getAnimations()
o:setAnimation(1, animations[5], true)

-- local slotNames = o:getSlotNames()
-- for i, slotName in ipairs(slotNames) do
--     print(i, slotName)
-- end

for i, slot in ipairs(o.slots) do
    print(i, slot.name)
end


local atlas2 = Spine.getAtlasData("goblins")
local skeleton2 = Spine.getSkeletonData("goblins", atlas2, .5)
local o2 = Spine.create(parent, skeleton2, 0, 0)
local animations2 = o2:getAnimations()
o2:setAnimation(1, animations2[1], true)
o2:setSkin("goblin")

local o3 = Spine.create(parent, skeleton2, 0, 0)
local animations2 = o3:getAnimations()
o3:setAnimation(1, animations2[1], true)
o3:setSkin("goblin")

local o4 = Spine.create(parent, skeleton2, 0, 0)
local animations2 = o4:getAnimations()
o4:setAnimation(1, animations2[1], true)
o4:setSkin("goblin")


o:inject(o2, "head", function(e)
    o2.x = e.x + 50
    o2.y = e.y
    o2.rotation = e.rotation
    o2.xScale = e.xScale
    o2.yScale = e.yScale
end)

o:inject(o3, "gun", function(e)
    o3.x = e.x + 50
    o3.y = e.y
    o3.rotation = e.rotation
    o3.xScale = e.xScale
    o3.yScale = e.yScale
end)

o4:scale(5, 5)
o:inject(o4, "raptor-front-leg", function(e)
    o4.x = e.x + 50
    o4.y = e.y
    o4.rotation = e.rotation
    o4.xScale = e.xScale
    o4.yScale = e.yScale
end)


timer.performWithDelay(1000, function()
    -- o:eject(o2)
    -- o2.x, o2.y = display.contentCenterX, display.contentCenterY
    
    -- o:changeInjectionSlot(o4, "raptor-back-leg")
    
    -- o4:removeSelf()
end, 1)