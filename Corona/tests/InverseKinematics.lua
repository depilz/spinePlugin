local text = display.newText("Drag me!", display.contentCenterX, display.screenOriginY + 50, native.systemFont, 24)

local atlas = Spine.getAtlasData("spineboy")
local skeleton = Spine.getSkeletonData("spineboy", atlas)

local parent = display.newGroup()
local o = Spine.create(parent, skeleton, display.contentCenterX, display.contentCenterY+100)
o:scale(.6, .6)
local animations = o:getAnimations()
o:setAnimation(0, animations[1], true)

local crosshair = o.ikConstraints[1].target

local prevX, prevY
o:addEventListener("touch", function(event)
    if not prevX and event.phase ~= "began" then return end

    if event.phase == "began" then
        prevX, prevY = event.x, event.y
        o.stage:setFocus(event.target)

    elseif event.phase == "moved" then
        local dx, dy = event.x - prevX, event.y - prevY
        prevX, prevY = event.x, event.y

        crosshair.x = crosshair.x + dx / o.xScale
        crosshair.y = crosshair.y + dy / o.yScale

    elseif event.phase == "ended" or event.phase == "cancelled" then
        prevX, prevY = nil, nil
        o.stage:setFocus(nil)
    end
end)

