-- s9: exposure with realistic "body part" split sets on the avatar skeleton (mix-and-match):
-- 8 part sets x 6 animations x 4 avatars; split, 30 frames, reassemble, 5 frames; oracle every frame.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock = C.mock; io.stdout:setvbuf("no")
local parts = {
  ["front arm"] = { "arm-front", "hand-front", "sleeve-front", "sleeve-inner-front" },
  ["back arm"] = { "arm-back", "hand-back", "sleeve-inner-back" },
  ["legs"] = { "leg-front", "leg-back", "boot-ribbon-front", "boot-ribbon-back" },
  ["head"] = { "base-head", "mouth", "nose", "ear", "eye-front-white", "eye-front-iris", "eye-front-pupil", "eye-back-white", "eye-back-iris", "eye-back-pupil" },
  ["hair"] = { "hair-back", "hair-bangs", "hair-side", "hair-side-front", "hair-side-back", "hair-patch" },
  ["cape"] = { "cape-back", "cape-up-back", "cape-red-down", "cape-red-up", "cape-blue-shoulder-back", "cape-blue-shoulder-front", "cape-blue-up-front", "cape-ribbon" },
  ["body"] = { "body", "body-dress", "body-up", "neck", "collar", "underskirt", "skirt" },
  ["bag"] = { "bag-base", "bag-top", "bag-strap-front", "bag-strap-back", "backpack", "backpack-up", "backpack-pocket" },
}
local names = {}; for k in pairs(parts) do names[#names + 1] = k end; table.sort(names)
local avatars = { "full-skins/girl", "full-skins/boy", "full-skins/girl-blue-cape", "full-skins/girl-spring-dress" }
local anims = { "aware", "blink", "dance", "dress-up", "idle", "walk" }
local cycles, badCycles, raisedCycles, perPart = 0, 0, 0, {}
local firstMsg
for _, part in ipairs(names) do
  perPart[part] = 0
  for _, av in ipairs(avatars) do
    for _, an in ipairs(anims) do
      cycles = cycles + 1
      local scene = display.newGroup()
      local obj = C.spine.create(C.data("mix-and-match", 0.5)); scene:insert(obj)
      obj:setSkin(av); obj:setAnimation(1, an, true)
      C.frame(obj); mock.endFrame()
      local sg = obj:split(parts[part]); scene:insert(sg)
      local bad, raised = false, false
      for f = 1, 35 do
        if f == 31 then obj:reassemble(); sg = nil end
        local ok, err = pcall(C.frame, obj); mock.endFrame()
        if not ok then raised = true; firstMsg = firstMsg or (part .. "/" .. av .. "/" .. an .. ": " .. tostring(err)); break end
        local e = C.check(obj, sg, nil, part .. "/" .. av .. "/" .. an .. " f" .. f)
        if #e > 0 then bad = true; firstMsg = firstMsg or e[1] end
      end
      if bad or raised then badCycles = badCycles + 1; perPart[part] = perPart[part] + 1 end
      if raised then raisedCycles = raisedCycles + 1 end
      pcall(function() obj:removeSelf() end); display.remove(scene); mock.endFrame()
    end
  end
end
local t = {}; for _, p in ipairs(names) do t[#t + 1] = p .. "=" .. perPart[p] end
print(("%d split->reassemble cycles: %d with a wrong frame or error (%d with draw() raising). per part (of 24): %s"):format(cycles, badCycles, raisedCycles, table.concat(t, ", ")))
if firstMsg then print("  first: " .. firstMsg:sub(1, 220)) end
C.expect(badCycles == 0, "body-part split sets disagree with the oracle or raise (render-7)")
C.done()
