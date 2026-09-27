local text = display.newText("Drag me!", display.contentCenterX, display.screenOriginY + 50, native.systemFont, 24)

local animationName = "raptor"
local atlas = Spine.getAtlasData(animationName)
local skeleton = Spine.getSkeletonData(animationName, atlas, .5)

local parent = display.newGroup()
local o = Spine.create(parent, skeleton, display.contentCenterX, display.contentCenterY+300)

------- ANIMATIONS ------------------------------------------------------------------------------------------------------

local animations = o:getAnimations()

o:setDefaultMix(300)
o:setMix(animations[1], animations[2], 100)

o:setAnimation(1, animations[4], true)

local queued1 = o:addAnimation(1, animations[2], false, 0)
if queued1 then
    queued1:setMixDuration(100, 0)
end
o:addAnimationAt(1, animations[3], false, 1200)
o:addAnimationAt(1, animations[4], false, 1800)
o:addAnimation(1, animations[5], true, 0)
o:addAnimation(2, animations[4], false, 3000)
o:addAnimation(3, animations[5], true, 0)
