-- findAnimation and addAnimation on a removed skeleton, in the dispose window (finalized, the next frame has not
-- begun) and after the next-frame hook. "cached": a method cached before removal raises the removed-skeleton error;
-- "method": obj:findAnimation(...) finds no method once RestoreTable stripped the metatable; "live": the control,
-- findAnimation answers true/false and addAnimation false for a missing name on a live skeleton.
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1]
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local obj = spine.create(data)
obj:setAnimation(1, "walk", true); obj:updateState(16); obj:draw()
local dead = "Skeleton belongs to a removed skeleton"

-- runs check once in the dispose window and once after the next-frame hook
local function bothWindows(check)
  obj:removeSelf(); S.endFrame()
  assert(getmetatable(obj) == nil, "RestoreTable left a metatable")
  check("dispose window")
  S.frame()
  check("after the hook")
end

if mode == "live" then
  local found, missing = obj:findAnimation("run"), obj:findAnimation("nope")
  local added = obj:addAnimation(1, "nope", true, 0)
  print("live findAnimation run", found, "nope", missing, "addAnimation nope", added)
  assert(found == true and missing == false, "findAnimation must answer true for a present name, false for a missing one")
  assert(added == false, "addAnimation must answer false for a missing name")
  assert(obj:addAnimation(1, "run", true, 0).animation ~= nil, "addAnimation of a present name returned no entry")
elseif mode == "cached" then
  local findAnimation, addAnimation = obj.findAnimation, obj.addAnimation
  bothWindows(function(window)
    print(window)
    S.raises(dead, findAnimation, obj, "run")
    S.raises(dead, addAnimation, obj, 1, "run", true, 0)
  end)
elseif mode == "method" then
  bothWindows(function(window)
    print(window)
    local err = S.raises("attempt to call", function() return obj:findAnimation("run") end)
    assert(err:find("a nil value", 1, true), "expected the nil-method call error")
  end)
end
print("survived")
