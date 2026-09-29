-- loadAtlas warns once per call, through Lua print, when a page declares pma: true, and the atlas still loads.
--   pma       a two-page atlas with pma: true on both pages: exactly one warning line
--   straight  the same pages without pma: no warning
--   print     print raising, then print nil: loadAtlas still returns the atlas alone
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1]
local dir = arg[0]:match("^(.*)/") .. "/assets/pma/"
local path = dir .. (mode == "straight" and "straight.atlas" or "pma.atlas")
local expected = "WARNING: plugin.spine: " .. path
  .. ": premultiplied-alpha atlas (pma: true) is not supported; export with straight alpha"

local realPrint = print
local lines = {}
print = function(...) lines[#lines + 1] = table.concat({ ... }, "\t") end

-- loadAtlasAlone: loadAtlas returns exactly one value, the atlas, with both pages' textures loaded (a previous
-- call's atlas is collected first: live pages are shared, not loaded again)
local function loadAtlasAlone()
  S.gcfull()
  local created = S.texturesCreated
  local n, atlas = (function(...) return select("#", ...), ... end)(spine.loadAtlas(path))
  assert(n == 1, "loadAtlas returned " .. n .. " values")
  assert(type(atlas) == "userdata", "loadAtlas returned " .. type(atlas))
  assert(S.texturesCreated - created == 2, "loadAtlas loaded " .. (S.texturesCreated - created) .. " of 2 pages")
end

if mode == "print" then
  print = function() error("user print raised") end
  loadAtlasAlone()
  print = nil
  loadAtlasAlone()
  print = realPrint
  print(mode, "ok")
  return
end

loadAtlasAlone()
print = realPrint
for _, l in ipairs(lines) do print("captured", l) end
if mode == "pma" then
  assert(#lines == 1, "expected one warning line, got " .. #lines)
  assert(lines[1] == expected, "unexpected warning: " .. lines[1])
else
  assert(#lines == 0, "a straight atlas printed " .. #lines .. " lines")
end
print(mode, "ok")
