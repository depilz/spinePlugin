local composer = require("composer")
local scene = composer.newScene()
function scene:create(event) display.newRect(self.view, 100, 100, 50, 50) end
scene:addEventListener("create", scene)
return scene
