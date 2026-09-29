-- A failed load names the runtime reader's or graphics.newTexture's reason after the path; the prefixes stay.
-- "json": well-formed JSON whose slot names a missing bone (the runtime's JSON reader asserts on a syntax error and
-- crashes on a missing parent bone, so neither is tested here). "skel": the line's .skel cut right after its version
-- string, with the version changed (a cut past the version check over-reads in the runtime's reader on both lines).
-- "atlas": graphics.newTexture raises for the atlas page.
local S = __stub
local mode = arg[1]
local reason = "decoder rejected the page"
local newTexture = graphics.newTexture
if mode == "atlas" then
  -- the plugin keeps graphics.newTexture from its require, so the raising wrapper goes in first
  graphics.newTexture = function(p)
    if p.filename:find("spineboy.png", 1, true) then error(reason, 0) end
    return newTexture(p)
  end
end
local spine = require("plugin.spine")

local function readFile(path)
  local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close(); return s
end
local function writeTemp(ext, contents)
  local base = os.tmpname() -- created empty: only its name is used
  os.remove(base)
  local path = base .. ext
  local f = assert(io.open(path, "wb")); f:write(contents); f:close()
  return path
end
-- loadSkeletonData(path) must raise exactly "Failed to load skeleton data: <path>: <expected reason>"
local function expectLoadError(path, atlas, expected)
  local message = S.raises("Failed to load skeleton data: ", spine.loadSkeletonData, path, atlas)
  os.remove(path)
  assert(message == "Failed to load skeleton data: " .. path .. ": " .. expected, "unexpected message: " .. message)
end

local atlas = mode ~= "atlas" and spine.loadAtlas("spineboy/spineboy.atlas")
if mode == "json" then
  local json = '{"skeleton":{"spine":"' .. os.getenv("SPINE_RUNTIME") .. '.0"},'
    .. '"bones":[{"name":"root"}],"slots":[{"name":"s","bone":"missing"}]}'
  expectLoadError(writeTemp(".json", json), atlas, "Slot bone not found: missing")
elseif mode == "skel" then
  -- header: 8 hash bytes, then the version string as a varint length + 1 and its bytes
  local skel = readFile("spineboy/spineboy.skel")
  local versionLength = skel:byte(9) - 1
  local version = "3" .. skel:sub(11, 9 + versionLength)
  local cut = skel:sub(1, 9) .. version
  expectLoadError(writeTemp(".skel", cut), atlas,
    "Skeleton version " .. version .. " does not match runtime version " .. os.getenv("SPINE_RUNTIME"))
elseif mode == "atlas" then
  local message = S.raises("Failed to load texture: ", spine.loadAtlas, "spineboy/spineboy.atlas")
  assert(message == "Failed to load texture: spineboy/spineboy.png: " .. reason, "unexpected message: " .. message)
end
atlas = nil
S.gcfull()
print(mode, ": textures created", S.texturesCreated, "released", S.texturesReleased, "live", S.liveTextureCount())
assert(S.liveTextureCount() == 0, "a failed load retains textures")
