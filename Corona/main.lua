display.setStatusBar(display.HiddenStatusBar)

local Spine = require('Spine')
local instances = {}

display.setDefault('background', 0.1)

local cx, cy = display.contentCenterX, display.contentCenterY
local w, h = display.actualContentWidth, display.actualContentHeight

local spines = {
    spineboy = { atlas = "spineboy.atlas", skeleton = "spineboy.skel"},
}

local parent = display.newGroup()

local function newSpine(name, x, y, scale, listener)
    local atlas = Spine.getAtlasData("spines/" .. spines[name].atlas)
    local skeleton = Spine.getSkeletonData("spines/" .. spines[name].skeleton, atlas)

    local o = Spine.create(parent, skeleton, x, y, listener)
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
    print("------ NEW EVENT -------")
    for k, v in pairs(e) do
        print(k, v)
    end
end

local function renewSpine()
    local o = table.remove(instances, 1)
    o:removeSelf()

    local spineboy = newSpine('spineboy', cx, cy, .4, eventListener)
    playFirstAnimation(spineboy)
    spineboy:addEventListener('touch', touch)
end


local spineboy = newSpine('spineboy', cx, cy, .4, eventListener)
playFirstAnimation(spineboy)
spineboy:addEventListener('touch', touch)

timer.performWithDelay(100, renewSpine, 0)

