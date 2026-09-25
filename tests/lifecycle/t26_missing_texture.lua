local spine = require("plugin.spine")
local S = __stub
-- dragon atlas with pages 2..5 dropped, next to this script
local atlasPath = arg[0]:match("^(.*)/") .. "/assets/dragon-partial/dragon.atlas"
local ok, err = pcall(spine.loadAtlas, atlasPath)
print("loadAtlas with pages 2..5 missing ->", ok, err)
S.gcfull()
print("textures created", S.texturesCreated, "released", S.texturesReleased, "(page-1 texture has no owner any more)")
local ok2 = pcall(spine.loadAtlas, atlasPath)
print("retry: textures created", S.texturesCreated, "(reused leaked entry, refCount now 2)")
