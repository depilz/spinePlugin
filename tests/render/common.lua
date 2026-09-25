-- Shared by the render tests: the Solar2D mock, the plugin, the renderfx inspection module and the oracle.
-- Tests load it with dofile(<their dir>/common.lua); run.sh passes their absolute path as arg[0].
local W = arg[0]:match("^(.*)/")
package.path = W .. "/?.lua;" .. package.path
local mock = require("mock_solar2d")
local spine, fx = require("plugin_spine"), require("renderfx")
local C = { mock = mock, spine = spine, fx = fx, failed = 0 }
local cache = {}
function C.data(name, scale, atlasName)
  local key = name .. (scale or 1) .. (atlasName or "")
  if cache[key] then return cache[key] end
  local atlas = spine.loadAtlas(("%s/%s.atlas"):format(name, atlasName or name))
  local d = spine.loadSkeletonData(("%s/%s.skel"):format(name, name), atlas, scale or 1)
  cache[key] = d
  return d
end
function C.check(obj, label)
  local main, split = fx.expected(obj)
  local errs = mock.compare(obj, main, label .. "/main")
  if split then
    local e2 = mock.compare(obj._splitGroup, split, label .. "/split")
    for _, e in ipairs(e2) do errs[#errs + 1] = e end
  end
  return errs
end
function C.frame(obj, dt) obj:updateState(dt or 16.666); obj:draw() end
-- C.expect(ok, msg): prints and counts a failed check; C.done() raises when any check failed (exit 1)
function C.expect(ok, msg)
  if not ok then C.failed = C.failed + 1; print("CHECK FAILED: " .. msg) end
end
function C.done()
  if C.failed > 0 then error(C.failed .. " check(s) failed", 0) end
end
return C
