display.setStatusBar(display.HiddenStatusBar)

local Spine = require('Spine')
local instances = {}

display.setDefault('background', 0.1)

local cx, cy = display.contentCenterX, display.contentCenterY
local w, h = display.actualContentWidth, display.actualContentHeight

local parent = display.newGroup()

local allSpines = {"alien", "celestial-circus", "chibi-stickers", "cloud-pot", "coin", "dragon", "goblins", "hero", "mix-and-match", "owl", "powerup", "raptor", "sack", "snowglobe", "speedy", "spineboy", "stretchyman", "tank", "vine", "windmill" }

local function newSpine(name, x, y, scale, listener)
    local atlas = Spine.getAtlasData(name)
    local skeleton = Spine.getSkeletonData(name, atlas)

    local o = Spine.create(parent, skeleton, x, y, listener)
    local skins = o:getSkins()
    for i = 1, #skins do
        print(skins[i])
    end
    local index = 1
    o:setSkin(skins[1])
    timer.performWithDelay(2000, function()
        index = (index%#skins) + 1
        o:setSkin(skins[index])
    end, 0)
    o:setDefaultMix(0.3)

    instances[#instances + 1] = o

    if scale then
        o:scale(scale, scale)
    end

    return o
end

local prevX, prevY
local function touch(e)
    if not prevX and e.phase ~= "began" then return end

    local instance = e.target

    if e.phase == "began" then
        prevX, prevY = e.x, e.y
        instance.stage:setFocus(instance)

    elseif e.phase == "moved" then
        local dx, dy = e.x - prevX, e.y - prevY
        prevX, prevY = e.x, e.y
        instance.x = instance.x + dx
        instance.y = instance.y + dy

        instance:physicsTranslate(dx, dy)

    elseif e.phase == "ended" or e.phase == "cancelled" then
        prevX, prevY = e.x, e.y
        instance.stage:setFocus(nil)
    end
end

local function playAllAnimations(o)
    local allAnimations = o:getAnimations()
    local index = 1
    o:setAnimation(0, allAnimations[index], true)
    timer.performWithDelay(3000, function()
        index = index + 1
        if index > #allAnimations then
            index = 1
        end
        o:setAnimation(0, allAnimations[index], true)
    end, 0)
end

local function playFirstAnimation(o)
    local allAnimations = o:getAnimations()
    o:setAnimation(0, allAnimations[1], true)
end




local prevTime = system.getTimer()
local function enterFrame(e)
    local time = system.getTimer()
    local dt = time - prevTime
    prevTime = time

    for i = 1, #instances do
        local o = instances[i]
        -- if o.isActive then
            o:updateState(dt)
            o:draw()
        -- end
    end
end
Runtime:addEventListener('enterFrame', enterFrame)

local function eventListener(e)
    -- print("------ NEW EVENT -------")
    -- for k, v in pairs(e) do
    --     print(k, v)
    -- end
end


local spineName = "studycat4_2"
-- local spineName = "chibi_stickers"

local function renewSpine()
    local o = table.remove(instances, 1)
    o:removeSelf()

    local x, y = math.random(0, w), math.random(0, h)

    local o = newSpine(spineName, x, y, .4, eventListener)
    playFirstAnimation(o)
    o:addEventListener('touch', touch)
end


-- local spineName = "studycat4_2"
local spine = allSpines[math.random(1, #allSpines)]
-- for i = 1, 20 do
    -- Not working: 4, 6, 14
    local o = newSpine(spineName, cx, cy, .4, eventListener)
    playAllAnimations(o)
    -- playFirstAnimation(o)
    o:addEventListener('touch', touch)
    print("------")
    local slot = o:getSlot("hat")
    local rect = display.newRect(slot.x, slot.y, 50, 50)
    -- o:insert(rect)
    local parent = display.newGroup()
    parent:insert(rect)
    parent:scale(.4, .4)
    parent.x, parent.y = o.x, o.y
    timer.performWithDelay(0, function ()
        print("---------- Slot found ----------")
        rect.x, rect.y = slot.x, slot.y
        rect.rotation = slot.rotation
        rect:setFillColor(slot.r, slot.g, slot.b)
    end, 0)
    o:setFillColor(1, 0, 0)
-- end

-- timer.performWithDelay(1, function()
--     for i = 1, 18 do
--         renewSpine()
--     end
-- end, 0)


local lastTime = system.getTimer()
local frameCount = 0
local lastMark = lastTime
Runtime:addEventListener("enterFrame", function(event)
    local time = event.time
    local dt = time - lastTime
    lastTime = time
    frameCount = frameCount + 1
    if time - lastMark > 1000 then
        print(("SPINES: %d, FPS: %d"):format(#instances, frameCount)) 
        frameCount = 0
        lastMark = time
    end
end)