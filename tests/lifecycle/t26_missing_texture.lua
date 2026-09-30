local spine = require("plugin.spine")
local S = __stub
-- t26_missing_texture.lua <atlas>: a multi-page atlas under assets/<line>/ with every page image but the first dropped
local atlasPath = arg[0]:match("^(.*)/") .. "/assets/" .. os.getenv("SPINE_RUNTIME") .. "/" ..
  assert(arg[1], "usage: t26_missing_texture.lua <atlas under assets/<line>/>")
for attempt = 1, 2 do
  local ok, err = pcall(spine.loadAtlas, atlasPath)
  print("attempt", attempt, "loadAtlas with every page but the first missing ->", ok, err)
  S.gcfull()
  print("textures created", S.texturesCreated, "released", S.texturesReleased, "live", S.liveTextureCount())
  assert(not ok, "loadAtlas must fail when pages are missing")
  assert(S.texturesCreated >= attempt and S.texturesReleased >= attempt, "page 1 never loaded: the atlas proves nothing")
  assert(S.liveTextureCount() == 0, "the failed loadAtlas retains its Atlas: textures still live")
end
