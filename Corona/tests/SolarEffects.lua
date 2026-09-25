local text = display.newText("Drag me!", display.contentCenterX, display.screenOriginY + 50, native.systemFont, 24)

local animationName = "raptor"
local atlas = Spine.getAtlasData(animationName)
local skeleton = Spine.getSkeletonData(animationName, atlas, .5)

local parent = display.newGroup()
local o = Spine.create(parent, skeleton, display.contentCenterX, display.contentCenterY+300)

o.fill.effect = "filter.sepia"
o.fill.effect.intensity = 1

timer.performWithDelay(1000, function()
    transition.loop(o.fill.effect, {time=2000, intensity=0, transition=easing.inQuad, iterations=0})
end)

------- ANIMATIONS ------------------------------------------------------------------------------------------------------

local animations = o:getAnimations()
o:setAnimation(1, animations[4], true)
