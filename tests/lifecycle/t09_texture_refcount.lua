local spine = require("plugin.spine")
local S = __stub
local order = arg[1] or "fifo"
local a1 = spine.loadAtlas("spineboy/spineboy.atlas")
local a2 = spine.loadAtlas("spineboy/spineboy.atlas")    -- same page image -> texture shared, refCount 2
print("textures created:", S.texturesCreated)
if order == "fifo" then a1 = nil; S.gcfull(); a2 = nil; S.gcfull()
else a2 = nil; S.gcfull(); a1 = nil; S.gcfull() end
print(order, "after both atlases collected: released", S.texturesReleased, "live", S.liveTextureCount())
local a3 = spine.loadAtlas("spineboy/spineboy.atlas")
a3 = nil; S.gcfull()
print("reload+collect: created", S.texturesCreated, "released", S.texturesReleased, "live", S.liveTextureCount())
-- control: single atlas lifecycle
