
local animationName = "spineboy"
local atlas = Spine.getAtlasData(animationName)

local skeleton = Spine.getSkeletonData(animationName, atlas, .3)
local parent = display.newGroup()

local o = Spine.create(parent, skeleton, display.contentCenterX, display.contentCenterY+100)
local animations = o:getAnimations()
o:removeSelf()

local timeStart = system.getTimer()
for i = 1, 200 do
    local o = Spine.create(parent, skeleton, math.random(0, display.actualContentWidth), math.random(0, display.actualContentHeight))
    o:setAnimation(0, animations[1], true)
end

print("Time: ", system.getTimer() - timeStart)


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