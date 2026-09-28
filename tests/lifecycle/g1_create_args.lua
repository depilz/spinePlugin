-- gap-6 g1: the real spine.create with a trailing argument keeps its listener; a bad listener raises.
local spine = require("plugin.spine")
local S = __stub
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
local expected
for _, extra in ipairs({ "none", "nil", "42" }) do
  local calls = 0
  local fn = function(e) calls = calls + 1 end
  local o
  if extra == "none" then o = spine.create(data, fn)
  elseif extra == "nil" then o = spine.create(data, fn, nil)
  else o = spine.create(data, fn, 42) end
  o:setAnimation(1, "walk", true); o:updateState(16)
  print("create(data, fn) with extra argument", extra, ": listener calls", calls)
  expected = expected or calls
  assert(calls > 0 and calls == expected, "create with a trailing argument drops the listener")
  o:removeSelf()
end
print("create(data, 123) ->", pcall(spine.create, data, 123))
assert(not pcall(spine.create, data, 123), "create with a non-function listener must raise")
S.frame(); S.gcfull()
