-- Physics constraints (Spine 4.3) driven from Lua.
--
-- Drag the skeleton to feel inertia (physics:translate), or use the on-screen
-- controls to change wind, gravity and mix live. The "Gust" button applies an
-- impulse through the new xVelocity/yVelocity accessors.

local atlas = Spine.getAtlasData("celestial-circus")
local skeleton = Spine.getSkeletonData("celestial-circus", atlas, 0.3)

local parent = display.newGroup()
local o = Spine.create(parent, skeleton, cx, cy - 40)
o:setAnimation(1, "swing", true)

local physics = o.physics

display.newText({
    text = "Drag me!", x = cx, y = oy + 40,
    font = native.systemFont, fontSize = 24,
})

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
        physics:translate(dx, dy)
    elseif event.phase == "ended" or event.phase == "cancelled" then
        prevX, prevY = nil, nil
        o.stage:setFocus(nil)
    end
    return true
end)

-- A horizontal on-screen control that reports a value in [min, max].
local function makeSlider(y, label, min, max, value, onChange)
    local width = math.min(w * 0.8, 520)
    local x0 = cx - width * 0.5

    local caption = display.newText({
        text = "", x = cx, y = y - 30, font = native.systemFont, fontSize = 18,
    })

    local track = display.newRect(cx, y, width, 6)
    track:setFillColor(0.45)

    local knob = display.newCircle(x0, y, 16)
    knob:setFillColor(0.3, 0.7, 1)
    knob.strokeWidth = 2
    knob:setStrokeColor(1)

    local function setValue(v)
        v = math.max(min, math.min(max, v))
        knob.x = x0 + (v - min) / (max - min) * width
        caption.text = ("%s: %.2f"):format(label, v)
        onChange(v)
    end

    knob:addEventListener("touch", function(event)
        if event.phase == "began" then
            display.getCurrentStage():setFocus(knob)
        elseif event.phase == "moved" then
            setValue(min + (event.x - x0) / width * (max - min))
        elseif event.phase == "ended" or event.phase == "cancelled" then
            display.getCurrentStage():setFocus(nil)
        end
        return true
    end)

    setValue(value)
end

makeSlider(h - 210, "Wind", -6, 6, physics.wind, function(v) physics.wind = v end)
makeSlider(h - 130, "Gravity", -10, 10, physics.gravity, function(v) physics.gravity = v end)
makeSlider(h - 50, "Mix", 0, 1, physics.mix, function(v) physics.mix = v end)

local gust = display.newText({
    text = "Gust", x = cx, y = oy + 80, font = native.systemFontBold, fontSize = 22,
})
gust:setFillColor(1, 0.85, 0.2)
gust:addEventListener("touch", function(event)
    if event.phase == "began" then
        physics.xVelocity = 400
        physics.yVelocity = -200
    end
    return true
end)
