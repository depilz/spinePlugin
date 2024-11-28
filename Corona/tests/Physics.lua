local text = display.newText("Drag me!", display.contentCenterX, display.screenOriginY + 50, native.systemFont, 24)

local atlas = Spine.getAtlasData("celestial-circus")
local skeleton = Spine.getSkeletonData("celestial-circus", atlas)

local parent = display.newGroup()
local o = Spine.create(parent, skeleton, display.contentCenterX, display.contentCenterY+100)
o:scale(.3, .3)
local animations = o:getAnimations()
o:setAnimation(0, animations[1], true)

local prevX, prevY
o:addEventListener("touch", function(event)
    if not prevX and event.phase ~= "began" then return end

    if event.phase == "began" then
        prevX, prevY = event.x, event.y
        o.stage:setFocus(event.target)

    elseif event.phase == "moved" then
        local dx, dy = event.x - prevX, event.y - prevY
        prevX, prevY = event.x, event.y

        o.x, o.y = o.x + dx, o.y + dy
        o:physicsTranslate(dx, dy)

    elseif event.phase == "ended" or event.phase == "cancelled" then
        prevX, prevY = nil, nil
        o.stage:setFocus(nil)
    end
end)

