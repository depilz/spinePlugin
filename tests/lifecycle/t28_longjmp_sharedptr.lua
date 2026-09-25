-- luaL_error longjmps over C++ frames holding std::shared_ptr locals (Lua built as C, as in this host).
local spine = require("plugin.spine")
local S = __stub
local mode = arg[1]
local atlas = spine.loadAtlas("spineboy/spineboy.atlas")
local data
if mode == "create-bad-listener" then
  data = spine.loadSkeletonData("spineboy/spineboy.json", atlas)
  print(pcall(spine.create, data, 123))              -- argument error after DataHolder::check copied a shared_ptr
elseif mode == "load-missing" then
  print(pcall(spine.loadSkeletonData, "spineboy/does-not-exist.json", atlas))   -- File not found (before check)
  print(pcall(spine.loadSkeletonData, "mix-and-match/mix-and-match.json", atlas)) -- regions missing -> load fails after check
end
data, atlas = nil, nil
S.gcfull()
print(mode, ": textures created", S.texturesCreated, "released", S.texturesReleased)
