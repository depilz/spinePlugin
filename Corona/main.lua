display.setStatusBar(display.HiddenStatusBar)

display.setDefault('background', 0.2)

ox, oy = display.safeScreenOriginX, display.safeScreenOriginY
cx, cy = display.contentCenterX, display.contentCenterY
w, h = display.actualContentWidth, display.actualContentHeight

_G.Spine = require('Spine')

_G.allSpines = {"chibi-stickers", "snowglobe", "dragon", "alien", "celestial-circus", "cloud-pot", "coin", "goblins", "hero", "mix-and-match", "owl", "powerup", "raptor", "sack", "speedy", "spineboy", "stretchyman",  "vine", "tank", "windmill" }


local tests = {
    {"Physics", "Physics"},
    {"Inverse Kinematics", "InverseKinematics"},
    {"Skins", "Skins"},
    {"Animations", "PlayAnimations"},
    {"Performance", "Performance"},
    {"Performance 2", "Performance2"},
    {"Injections", "Injections"},
}

local buttons = display.newGroup()
local ySpacing = 100
local yStart = oy + ySpacing
local Widget = require('widget')
for i, spine in ipairs(tests) do
    local name, file = spine[1], spine[2]

    local button = Widget.newButton{
        x = cx,
        y = yStart + (i - 1) * ySpacing,
        width = 400,
        height = 80,
        label = name,
        shape = "roundedRect",
        fontSize = 40,
        fillColor = { default={0.3,0.7,1,1}, over={0.2,0.5,0.7,1} },
        labelColor = { default={1,1,1,1}, over={.9,.9,.9,1} },
        onRelease = function()
            require("tests." .. file)
            buttons.isVisible = false
        end
    }

    buttons:insert(button)
end

-- require("tests.InverseKinematics")
-- require("tests.Performance")
-- require("tests.Performance2")
-- buttons.isVisible = false