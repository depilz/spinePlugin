-- S24 (D191): the line's plugin refuses to open next to the shipped plugin.spine 1.5.0 (4.2 only: the suite stages
-- that dylib on 4.2). The Simulator's require stores the 1.5.0 module table in package.loaded under its underscored
-- name, plugin_spine; the line's plugin then raises its sibling-guard error before its load banner.
--   legacy: plugin.spine loaded, then the line's plugin required.
-- CHECK legacy: plugin.spine loaded as a 1.x module table (no version field) in package.loaded["plugin_spine"].
-- CHECK guard: requiring the line's plugin failed with the guard's message naming both plugins.
local L = require("simlib")
L.open("s24_sibling_guard " .. L.arg)
L.expect("legacy", "guard")
local legacy = L.loadPlugin("plugin.spine")
L.check("legacy", type(legacy) == "table" and legacy.version == nil and package.loaded["plugin_spine"] == legacy,
  "plugin.spine", type(legacy), type(legacy) == "table" and tostring(legacy.version) or "")
local ok, err = pcall(require, L.plugin)
io.stdout:flush()
local want = ("%s cannot load: plugin.spine is already loaded in this app. Use only one Spine plugin per app."):format(
  L.plugin)
L.check("guard", not ok and tostring(err):find(want, 1, true) ~= nil, "require('" .. L.plugin .. "')", ok, tostring(err))
L.finish(0)
