local text = display.newText("Drag me!", display.contentCenterX, display.screenOriginY + 50, native.systemFont, 24)

local animationName = "goblins"
local atlas = Spine.getAtlasData(animationName)
local skeleton = Spine.getSkeletonData(animationName, atlas)

local parent = display.newGroup()
local o = Spine.create(parent, skeleton, display.contentCenterX, display.contentCenterY+100)

local animations = o:getAnimations()
o:setAnimation(0, animations[1], true)


------ SKINS -----------------------------------------------------------------------------------------------------------

local skins = o:getSkins()

local index = 2
o:setSkin(skins[2])
timer.performWithDelay(1500, function()
    index = (index % #skins) + 1
    o:setSkin(skins[index])
    print("Skin:", skins[index])
end, 0)
