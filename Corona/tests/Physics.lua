local text = display.newText("Drag me!", display.contentCenterX, display.screenOriginY + 50, native.systemFont, 24)

-- _G.allSpines = {"alien", "celestial-circus", "cloud-pot", "coin", "goblins", "hero", "mix-and-match", "owl", "powerup", "raptor", "sack", "speedy", "spineboy", "stretchyman",  "vine", "tank", "windmill" }
-- local atlas = Spine.getAtlasData("celestial-circus")
-- local skeleton = Spine.getSkeletonData("celestial-circus", atlas)
local atlas = Spine.getAtlasData(allSpines[2])
local skeleton = Spine.getSkeletonData(allSpines[2], atlas, .3)

local parent = display.newGroup()
local o = Spine.create(parent, skeleton, display.contentCenterX, display.contentCenterY+100)
local animations = o:getAnimations()
o:setAnimation(1, animations[1], true)

local prevX, prevY
local physics = o.physics
o:addEventListener("touch", function(event)
    if not prevX and event.phase ~= "began" then return end

    if event.phase == "began" then
        prevX, prevY = event.x, event.y
        -- o.stage:setFocus(event.target)

    elseif event.phase == "moved" then
        local dx, dy = event.x - prevX, event.y - prevY
        prevX, prevY = event.x, event.y

        o.x = o.x + dx
        o.y = o.y + dy
        -- print(o.y)
        physics:translate(dx, dy)

    elseif event.phase == "ended" or event.phase == "cancelled" then
        prevX, prevY = nil, nil
        o.stage:setFocus(nil)
    end
end)

-- local windIn, windOut
-- function windIn()
--     transition.to(physics, {
--         time = math.random(200, 700),
--         wind = 2.5,
--         transition.inQuad,
--         onComplete = windOut
--     })
-- end

-- function windOut()
--     transition.to(physics, {
--         time = math.random(200, 700),
--         wind = 2,
--         transition.outQuad,
--         onComplete = windIn
--     })
-- end

-- windIn()


local rect = display.newRect(display.contentCenterX, display.contentCenterY, 100, 100)
rect:setFillColor(1, .1)
rect.strokeWidth = 2
rect:setStrokeColor(1, 0, 0)

timer.performWithDelay(1, function()
    local bounds = o.contentBounds
    rect.x, rect.y = (bounds.xMin + bounds.xMax) * .5, (bounds.yMin + bounds.yMax) * .5
    rect.width, rect.height = (bounds.xMax - bounds.xMin), (bounds.yMax - bounds.yMin)

end, 0)
rect:addEventListener("touch", function(event)
    if not prevX and event.phase ~= "began" then return end

    if event.phase == "began" then
        prevX, prevY = event.x, event.y
        -- o.stage:setFocus(event.target)

    elseif event.phase == "moved" then
        local dx, dy = event.x - prevX, event.y - prevY
        prevX, prevY = event.x, event.y

        o.x = o.x + dx
        o.y = o.y + dy
        -- print(o.y)
        physics:translate(dx, dy)

    elseif event.phase == "ended" or event.phase == "cancelled" then
        prevX, prevY = nil, nil
        o.stage:setFocus(nil)
    end
end)