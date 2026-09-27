-- T10: spine.create(data, listener, <extra arg>) refs the wrong stack slot (luaL_ref pops the top).
local fx = require("realdata_fixture")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local data = fx.loadData("spineboy/spineboy.atlas", "spineboy/spineboy.json")
local counts = {}
for _, extra in ipairs({"none", "nil", "number"}) do
  local calls = 0
  local fn = function(ev) calls = calls + 1 end
  local s
  if extra == "none" then s = fx.createPlugin(data, fn)
  elseif extra == "nil" then s = fx.createPlugin(data, fn, nil)
  else s = fx.createPlugin(data, fn, 42) end
  s:setAnimation(1, "walk", true)
  for i = 1, 20 do s:updateState(16) end
  print(("create(data, fn%s): listener calls = %d"):format(extra == "none" and "" or (", " .. extra), calls))
  counts[#counts + 1] = calls
end
C.expect(counts[2] == counts[1] and counts[3] == counts[1], "a trailing argument loses the listener (animation-18)")
C.done()
