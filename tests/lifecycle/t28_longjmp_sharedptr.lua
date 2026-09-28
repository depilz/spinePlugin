-- luaL_error longjmps over C++ frames holding std::shared_ptr locals (Lua built as C, as in this host).
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1]
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data
if mode == "create-bad-listener" then
  data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
  print(pcall(spine.create, data, 123))              -- argument error after DataHolder::check copied a shared_ptr
elseif mode == "load-missing" then
  -- the line's skeleton whose slot names a missing bone, next to this script: the reader fails after the atlas check
  local badPath = arg[0]:match("^(.*)/") .. "/assets/" .. os.getenv("SPINE_RUNTIME") .. "/bad-slot/skeleton.json"
  local ok, err = pcall(spine.loadSkeletonData, "spineboy/does-not-exist.json", atlas)
  print(ok, err)
  assert(not ok, "loading a missing file must fail")
  ok, err = pcall(spine.loadSkeletonData, badPath, atlas)
  print(ok, err)
  assert(not ok and tostring(err):find("Failed to load skeleton data", 1, true), "the bad-slot load must fail after the atlas check")
elseif mode == "inject-missing-slot" then
  -- a missing slot must raise before inject ejects, inserts or refs the object
  data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
  local obj = spine.create(data)
  obj:setAnimation(1, "walk", true); obj:updateState(16)
  local a, b = display.newGroup(), display.newGroup()
  local fired = 0
  obj:inject(a, "head", function() fired = fired + 1 end)
  local ok, err = pcall(obj.inject, obj, a, "no-such-slot")
  print(ok, err)
  assert(not ok and tostring(err):find("Slot not found", 1, true), "inject with a missing slot must fail")
  assert(not pcall(obj.inject, obj, b, "no-such-slot"), "inject with a missing slot must fail")
  assert(b.parent ~= obj, "a failed inject inserted the object into the skeleton")
  obj:draw()
  print("injection listener calls after the failed re-inject", fired)
  assert(fired > 0, "a failed re-inject ejected the object")
  obj:removeSelf(); obj = nil
  S.frame()
end
data, atlas = nil, nil
S.gcfull()
print(mode, ": textures created", S.texturesCreated, "released", S.texturesReleased, "live", S.liveTextureCount())
assert(S.texturesCreated > 0 and S.liveTextureCount() == 0, "the raised call retains the Atlas: textures still live after dropping data and atlas")
