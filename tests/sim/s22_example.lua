-- S22: one menu scene of the line's example project (Corona/ on 4.2, Corona43/ on 4.3; suite.sh runs this script in
-- a copy of it, its main.lua as example_main.lua). The example's main.lua builds the menu, the button of the scene
-- named by the argument is pressed (a touch began/ended on it, so its onRelease opens the scene and hides the menu),
-- and the scene runs 10 s. s22_example.py checks the stdout log.
local L = require("simlib")
local RUN_MS = 10000
L.watchdogMs = RUN_MS + 20000
L.open("s22_example " .. L.arg)
L.expect("menu")
L.loadPlugin()

-- label: the menu label main.lua gives the scene module
local f = assert(io.open(system.pathForFile("example_main.lua", system.ResourceDirectory)))
local label = f:read("*a"):match('{"([^"]+)", "' .. L.arg .. '"}')
f:close()

-- findButton group: the widget button labelled label under group, and the menu group holding it
local function findButton(group)
  for i = 1, group.numChildren or 0 do
    local child = group[i]
    if child.getLabel and child:getLabel() == label then return child, group end
    local button, menu = findButton(child)
    if button then return button, menu end
  end
end

local function press(button)
  local b = button.contentBounds
  local event = { name = "touch", id = "s22", x = (b.xMin + b.xMax) / 2, y = (b.yMin + b.yMax) / 2 }
  for _, phase in ipairs({ "began", "ended" }) do
    event.phase = phase
    button:dispatchEvent(event)
  end
end

local ok, err = pcall(require, "example_main")
if not ok then L.log("ERROR", "example_main", err); L.finish(1) end
local button, menu = findButton(display.getCurrentStage())
L.log("menu", label, button ~= nil)
if not button then
  L.check("menu", false, "no button labelled", label)
  L.finish(1)
end
ok, err = pcall(press, button)
if not ok then L.log("ERROR", "press", err) end
L.check("menu", ok and package.loaded["tests." .. L.arg] ~= nil and not menu.isVisible, label)
timer.performWithDelay(RUN_MS, function() L.finish(0) end)
