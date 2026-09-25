local composer = require("composer")
local scene = composer.newScene()
function scene:create(event)
  local S1 = _G.S1
  local obj = S1.spine.create(S1.data)
  self.view:insert(obj)
  obj.x, obj.y = 300, 500
  obj:setAnimation(1, "walk", true)
  obj:updateState(16); obj:draw()
  S1.sceneRec = S1.instrument("D composer.gotoScene + composer.removeScene", obj)
end
scene:addEventListener("create", scene)
return scene
