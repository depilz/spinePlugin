local text = display.newText("Drag me!", display.contentCenterX, display.screenOriginY + 50, native.systemFont, 24)

local animationName = "spineboy"
local atlas = Spine.getAtlasData(animationName)
local skeleton = Spine.getSkeletonData(animationName, atlas, .5)

local parent = display.newGroup()
local o = Spine.create(parent, skeleton, display.contentCenterX, display.contentCenterY + 260)

local animations = o:getAnimations()

o:setListener(function(event)
    if event.name == "spine" then
        print("[listener]", event.phase, event.animation, "track", event.trackIndex)
    else
        print("[custom event]", event.name, event.int, event.float, event.string)
    end
end)

o:setDefaultMix(120)
o:setAnimation(1, animations[1], false)
o:addAnimation(1, animations[2], false, 0)
o:addAnimation(1, animations[1], true, 0)
