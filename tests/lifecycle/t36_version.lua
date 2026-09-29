-- The module table carries the plugin's version without the "v" and the runtime's major.minor (D27), pinned per line.
local expected = {
  ["4.2"] = {version = "2.0.0", runtimeVersion = "4.2"},
  ["4.3"] = {version = "3.0.0", runtimeVersion = "4.3"},
}
local line = os.getenv("SPINE_RUNTIME")
local want = assert(expected[line], "no pinned version for line " .. tostring(line))
local spine = require("plugin.spine")
for key, value in pairs(want) do
  assert(spine[key] == value, key .. " is " .. tostring(spine[key]) .. ", expected " .. value)
end
print("version", spine.version, "runtimeVersion", spine.runtimeVersion)
