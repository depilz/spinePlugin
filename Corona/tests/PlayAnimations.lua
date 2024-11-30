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

o:setAnimation(0, animations[1], false)
o:addAnimation(0, animations[2], false, 0)
o:addAnimation(0, animations[3], false, 0)
o:addAnimation(0, animations[4], false, 0)
o:addAnimation(0, animations[5], true, 0)
o:addAnimation(0, animations[4], false, 3000)
o:addAnimation(0, animations[5], true, 0)
