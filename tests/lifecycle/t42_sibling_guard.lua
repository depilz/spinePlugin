-- One Spine plugin per app (D191): opening the line's plugin raises, before any side effect, when a sibling Spine
-- plugin is already loaded in the Lua state, and loads otherwise. The host preloads the line's entry as plugin.spine;
-- the modes that seed package.loaded["plugin.spine"] require it under its real name instead.
--   alone      require("plugin.spine") loads (require's own sentinel for the module is no sibling)
--   other      the other line already opened (its registry key): raises naming both plugins
--   legacy     a loaded plugin.spine 1.x (its module table has no version and runtimeVersion): raises naming both
--   legacy_underscore  the same 1.x table under package.loaded["plugin_spine"], where Solar2D's require stores it
--   versioned  package.loaded["plugin.spine"] is a line's module table (version, runtimeVersion): loads
--   reopen     the same line opened again after package.loaded forgot it: loads
local S = __stub
local mode = arg[1]
local LINES = { ["4.2"] = "plugin.spine42", ["4.3"] = "plugin.spine43" }
local line = os.getenv("SPINE_RUNTIME")
local self = assert(LINES[line], "no plugin name for line " .. tostring(line))
local other = LINES[line == "4.2" and "4.3" or "4.2"]
package.preload[self] = package.preload["plugin.spine"]

local function message(sibling)
  return ("%s cannot load: %s is already loaded in this app. Use only one Spine plugin per app."):format(self, sibling)
end

-- the open raises exactly message(sibling) and leaves no trace: no module, no display group taken
local function refuses(name, sibling)
  local err = S.raises(message(sibling), require, name)
  assert(err == message(sibling), "unexpected message: " .. err)
  assert(not err:find("^WARNING: plugin%.spine:"), "the message reads as a plugin warning")
  assert(type(package.loaded[name]) ~= "table", "the module loaded")
  assert(S.groupsCreated == 0, "the open ran past the guard: " .. S.groupsCreated .. " display groups")
end

local function loads(name)
  local spine = require(name)
  assert(type(spine) == "table" and type(spine.create) == "function", "no module table from " .. name)
  print("loaded", name, spine.version, spine.runtimeVersion)
  return spine
end

if mode == "alone" then
  loads("plugin.spine")
elseif mode == "other" then
  debug.getregistry().plugin_spine_line = other
  refuses("plugin.spine", other)
elseif mode == "legacy" or mode == "legacy_underscore" then
  local f = function() end
  package.loaded[mode == "legacy" and "plugin.spine" or "plugin_spine"] = { loadAtlas = f, loadSkeletonData = f, create = f }
  refuses(self, "plugin.spine")
elseif mode == "versioned" then
  package.loaded["plugin.spine"] = { loadAtlas = function() end, version = "0.0.0", runtimeVersion = line }
  loads(self)
elseif mode == "reopen" then
  loads("plugin.spine")
  package.loaded["plugin.spine"] = nil
  loads("plugin.spine")
  loads(self)
else
  error("unknown mode " .. tostring(mode))
end
print("t42", mode, "ok")
