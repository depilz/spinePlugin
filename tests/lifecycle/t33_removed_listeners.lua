-- add/removeEventListener on a skeleton removed with obj:removeSelf(). Solar2D's EventDispatcher calls its helpers
-- through self (getOrCreateTable, didRemoveListener, _setHasListener), so the removed skeleton must still answer
-- them. "window": in the removal frame, the helpers are the live object's own functions, both calls work and a
-- display or plugin key still reads nil; once RestoreTable stripped the metatable, obj:addEventListener is the
-- generic nil-call. "finalize": a user finalize listener that removes itself and adds a listener does not raise.
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1]
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj = spine.create(data)
obj:setAnimation(1, "walk", true); obj:updateState(16); obj:draw()
local helpers = { "getOrCreateTable", "didRemoveListener", "_setHasListener" }

if mode == "window" then
  local live = {}
  for _, k in ipairs(helpers) do live[k] = obj[k] end
  local before = function() end
  obj:addEventListener("tap", before)
  obj:removeSelf()
  local fn = function() end
  local ok, added = pcall(function() return obj:addEventListener("tap", fn) end)
  print("window a: addEventListener", ok, added)
  assert(ok and added == true, "addEventListener failed after removeSelf: " .. tostring(added))
  obj:removeEventListener("tap", fn)
  obj:removeEventListener("tap", before)
  assert(not obj:respondsToEvent("tap"), "removeEventListener left a listener after removeSelf")
  for _, k in ipairs(helpers) do
    assert(live[k] ~= nil and rawequal(obj[k], live[k]), k .. " is not the live object's function after removeSelf")
  end
  assert(obj.x == nil and obj.numChildren == nil and obj.findAnimation == nil and obj.removeSelf == nil,
         "a removed skeleton answers a display or plugin key")
  S.endFrame()
  assert(getmetatable(obj) == nil, "RestoreTable left a metatable")
  local err = S.raises("attempt to call", function() return obj:addEventListener("tap", fn) end)
  assert(err:find("a nil value", 1, true), "expected the nil-method call error")
elseif mode == "finalize" then
  local results = {}
  local function onFinalize(e)
    results[#results + 1] = { pcall(e.target.removeEventListener, e.target, "finalize", onFinalize) }
    results[#results + 1] = { pcall(e.target.addEventListener, e.target, "tap", function() end) }
  end
  obj:addEventListener("finalize", onFinalize)
  obj:removeSelf()
  S.endFrame()
  assert(#results == 2, "the finalize listener did not run")
  for i, r in ipairs(results) do
    print("finalize call", i, r[1], r[2])
    assert(r[1], "a listener call inside finalize raised: " .. tostring(r[2]))
  end
end
S.frame()
S.gcfull()
print("survived")
