local text = display.newText("Drag me!", display.contentCenterX, display.screenOriginY + 50, native.systemFont, 24)

local atlas = Spine.getAtlasData("spineboy")
local skeleton = Spine.getSkeletonData("spineboy", atlas, .6)

local parent = display.newGroup()
local o = Spine.create(parent, skeleton, display.contentCenterX, display.contentCenterY+100)
local animations = o:getAnimations()
o:setAnimation(1, animations[1], true)

local crosshair = o:getIKConstraint("aim-ik").target

local prevX, prevY
o:addEventListener("touch", function(event)
    if not prevX and event.phase ~= "began" then return end

    if event.phase == "began" then
        prevX, prevY = event.x, event.y
        o.stage:setFocus(event.target)

    elseif event.phase == "moved" then
        crosshair:setWorldPosition(o:contentToLocal(event.x, event.y))

    elseif event.phase == "ended" or event.phase == "cancelled" then
        prevX, prevY = nil, nil
        o.stage:setFocus(nil)
    end
end)

