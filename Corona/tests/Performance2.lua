
local animationName = "raptor"
local atlas = Spine.getAtlasData(animationName)

local skeleton = Spine.getSkeletonData(animationName, atlas, .3)
local parent = display.newGroup()


local o = Spine.create(parent, skeleton, display.contentCenterX, display.contentCenterY+100)
local animations = o:getAnimations()
local anim = animations[1]
o:removeSelf()


local instances = {}
for i = 1, 50 do
    instances[i] = Spine.create(parent, skeleton, math.random(0, display.actualContentWidth), math.random(0, display.actualContentHeight))
    instances[i]:setAnimation(0, anim, true)
end

local function renew()
    for i = 1, 50 do
        instances[i]:removeSelf()
        instances[i] = Spine.create(parent, skeleton, math.random(0, display.actualContentWidth), math.random(0, display.actualContentHeight))
        instances[i]:setAnimation(0, anim, true)
    end
end

timer.performWithDelay(1, renew, 0)



local textX, textY = cx, oy + 50
local back = display.newRect(textX, textY, 200, 40)
back:setFillColor(0, 0, 0, .5)

local fpsText = display.newText("FPS", textX, textY, native.systemFont, 24)

local frameCount = 0
local prevTime = system.getTimer()
Runtime:addEventListener("enterFrame", function()
    frameCount = frameCount + 1

    local time = system.getTimer()
    local dt = time - prevTime

    if dt > 1000 then
        local fps = frameCount / (dt / 1000)
        fpsText.text = ("FPS: %.2f"):format(fps)

        frameCount = 0
        prevTime = time
    end
end)