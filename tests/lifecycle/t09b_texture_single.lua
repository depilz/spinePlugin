local spine = require("plugin.spine")
local S = __stub
for i = 1, 3 do local a = spine.loadAtlas("spineboy/spineboy.atlas"); a = nil; S.gcfull() end
print("single-owner cycles: created", S.texturesCreated, "released", S.texturesReleased, "live", S.liveTextureCount())
