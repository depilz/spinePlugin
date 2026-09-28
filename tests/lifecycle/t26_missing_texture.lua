local spine = require("plugin.spine")
local S = __stub
-- the line's dragon atlas with every page image but the first dropped, next to this script
local atlasPath = arg[0]:match("^(.*)/") .. "/assets/" .. os.getenv("SPINE_RUNTIME") .. "/dragon-partial/dragon.atlas"
for attempt = 1, 2 do
  local ok, err = pcall(spine.loadAtlas, atlasPath)
  print("attempt", attempt, "loadAtlas with every page but the first missing ->", ok, err)
  S.gcfull()
  print("textures created", S.texturesCreated, "released", S.texturesReleased, "live", S.liveTextureCount())
  assert(not ok, "loadAtlas must fail when pages are missing")
  assert(S.liveTextureCount() == 0, "the failed loadAtlas retains its Atlas: textures still live")
end
