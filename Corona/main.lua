display.setStatusBar(display.HiddenStatusBar)

display.setDefault('background', 0.1)

local cx, cy = display.contentCenterX, display.contentCenterY
local w, h = display.actualContentWidth, display.actualContentHeight

local parent = display.newGroup()

_G.Spine = require('Spine')

_G.allSpines = {"alien", "celestial-circus", "cloud-pot", "coin", "goblins", "hero", "mix-and-match", "owl", "powerup", "raptor", "sack", "speedy", "spineboy", "stretchyman",  "vine" }
-- not working: "chibi-stickers", "snowglobe""tank", "windmill", "dragon"


local tests = {
    {"Physics", "Physics"},
    {"Inverse Kinematics", "InverseKinematics"},
    {"Skins", "Skins"},
    {"Animations", "PlayAnimations"},
}


local buttons = display.newGroup()
local yStart = 50
local ySpacing = 50
local Widget = require('widget')
for i, spine in ipairs(tests) do
    local name, file = spine[1], spine[2]

    local button = Widget.newButton{
        x = cx,
        y = yStart + (i - 1) * ySpacing,
        width = 200,
        height = 40,
        label = name,
        shape = "roundedRect",
        fontSize = 20,
        fillColor = { default={0.3,0.7,1,1}, over={0.2,0.5,0.7,1} },
        labelColor = { default={1,1,1,1}, over={.9,.9,.9,1} },
        onRelease = function()
            require("tests." .. file)
            buttons.isVisible = false
        end
    }

    buttons:insert(button)
end

