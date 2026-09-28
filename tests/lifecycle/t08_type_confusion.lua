local spine = require("plugin.spine")
local which = arg[1]
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
print("atlas and data have separate metatables:", getmetatable(atlas) ~= getmetatable(data))
if which == "create-with-atlas" then
  print("spine.create(atlas) ...")      -- easy slip: passing the atlas instead of the skeleton data
  print(pcall(spine.create, atlas))
elseif which == "load-with-data" then
  print("spine.loadSkeletonData(path, data) ...")
  print(pcall(spine.loadSkeletonData, "spineboy/spineboy.json", data))
end
print("survived")
