local spine = require("plugin.spine")
local S = __stub
-- the line's dragon atlas with every page image but the first dropped, next to this script
local atlasPath = arg[0]:match("^(.*)/") .. "/assets/" .. os.getenv("SPINE_RUNTIME") .. "/dragon-partial/dragon.atlas"
local ok, err = pcall(spine.loadAtlas, atlasPath)
print("loadAtlas with every page but the first missing ->", ok, err)
S.gcfull()
print("textures created", S.texturesCreated, "released", S.texturesReleased, "(page-1 texture has no owner any more)")
local ok2 = pcall(spine.loadAtlas, atlasPath)
print("retry: textures created", S.texturesCreated, "(reused leaked entry, refCount now 2)")
