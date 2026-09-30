-- Slider constraints (Spine 4.3) driven from Lua.
--
-- The "diamond" skeleton has a slider constraint named "rotation" that applies
-- its "rotation" animation. Writing skeleton.sliders.rotation.time detaches the
-- constraint's driving bone and scrubs the animation manually, while .mix fades
-- the constraint in and out.

local atlas = Spine.getAtlasData("diamond")
local skeleton = Spine.getSkeletonData("diamond", atlas, 0.4)

local parent = display.newGroup()
local o = Spine.create(parent, skeleton, cx, cy - 40)

local slider = o.sliders.rotation

display.newText({
    text = "Slider constraint: " .. slider.name,
    x = cx, y = oy + 40, font = native.systemFont, fontSize = 24,
})

-- A horizontal on-screen control that reports a value in [min, max].
local function makeSlider(y, label, min, max, value, onChange)
    local width = math.min(w * 0.8, 520)
    local x0 = cx - width * 0.5

    local caption = display.newText({
        text = "", x = cx, y = y - 34, font = native.systemFont, fontSize = 20,
    })

    local track = display.newRect(cx, y, width, 6)
    track:setFillColor(0.45)

    local knob = display.newCircle(x0, y, 18)
    knob:setFillColor(0.3, 0.7, 1)
    knob.strokeWidth = 2
    knob:setStrokeColor(1)

    local function setValue(v)
        v = math.max(min, math.min(max, v))
        knob.x = x0 + (v - min) / (max - min) * width
        caption.text = ("%s: %.2f"):format(label, v)
        onChange(v)
        o:draw()
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

makeSlider(h - 150, "Time", 0, slider.duration, 0, function(v)
    slider.time = v
end)

makeSlider(h - 60, "Mix", 0, 1, slider.mix, function(v)
    slider.mix = v
end)
