-- Load/unload SkeletonData repeatedly (linked meshes, sequences, deform) and exercise skins:
-- detects refcount imbalances (leak = attachments never reach refcount 0; double free = ASan).
local spine = require("plugin.spine")
local S = __stub
local name, ext, N = arg[1], arg[2] or "json", tonumber(arg[3] or "20")
local function once(withSkins)
  local atlas = spine.loadAtlas(name .. "/" .. name .. ".atlas")
  local data = spine.loadSkeletonData(name .. "/" .. name .. "." .. ext, atlas)
  if withSkins then
    local obj = spine.create(data)
    local skins = obj:getSkins()
    local custom = obj:createSkin("c")
    for i, sk in ipairs(skins) do
      if i % 2 == 0 then custom:addSkin(sk) end
    end
    local copy = obj:createSkin("copy")
    for i, sk in ipairs(skins) do if i % 3 == 0 then copy:copySkin(sk) end end   -- newLinkedMesh / copy()
    obj:setSkin(copy); obj:setSlotsToSetupPose()
    local anims = obj:getAnimations()
    obj:setAnimation(1, anims[1], true)
    for f = 1, 5 do obj:updateState(33); obj:draw() end
    obj:setSkin(custom); obj:setSlotsToSetupPose()
    for f = 1, 5 do obj:updateState(33); obj:draw() end
    -- remove every attachment of the applied custom skin while slots still show them
    for _, a in ipairs(custom:getAttachments()) do end
    obj:removeSelf(); S.frame()
  end
end
for i = 1, 3 do once(true); S.gcfull() end
S.gcfull()
local h0 = __native.heap()
for i = 1, N do once(arg[4] == "skins"); S.gcfull() end
S.gcfull()
local h1 = __native.heap()
print(string.format("%s.%s x%d (%s): native heap +%.1f KB (%.0f B/iter); textures created %d released %d",
  name, ext, N, arg[4] or "load-only", (h1 - h0) / 1024, (h1 - h0) / N, S.texturesCreated, S.texturesReleased))
