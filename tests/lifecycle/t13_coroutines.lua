local mode = arg[1]
local S = __stub
if mode == "require-in-coroutine" then
  -- plugin first required from a coroutine (e.g. an async loader); SpineTextureLoader keeps that thread's L
  local spine
  local co = coroutine.create(function() spine = require("plugin.spine") end)
  assert(coroutine.resume(co)); co = nil
  S.gcfull()   -- the finished coroutine (and its lua_State) is collected
  print("coroutine collected; loading an atlas from the main thread")
  local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
  print("survived, textures", S.texturesCreated)
elseif mode == "fill-in-coroutine" then
  local spine = require("plugin.spine")
  local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
  local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
  local obj = spine.create(data)
  local co = coroutine.create(function() obj.fill.a = 0.5 end)   -- SpineFill stores this coroutine's L
  assert(coroutine.resume(co)); co = nil
  S.gcfull()
  print("coroutine collected; SpineFill userdata is pinned until lua_close, where its __gc calls luaL_unref(deadL)")
elseif mode == "listener-thread" then
  local spine = require("plugin.spine")
  local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
  local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
  local obj = spine.create(data, function(e)
    print("listener runs on main thread:", __native.isMain(), "coroutine.running():", coroutine.running())
  end)
  local co = coroutine.create(function()
    print("inside coroutine, isMain:", __native.isMain())
    obj:setAnimation(1, "walk", true)
    obj:updateState(16)
  end)
  print(coroutine.resume(co))
end
