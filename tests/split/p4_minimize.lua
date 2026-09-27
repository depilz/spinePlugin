-- minimize a split set that makes the draw after reassemble() raise (mix-and-match, p3 "once" trial 56)
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local name, skin, anim = "mix-and-match", "full-skins/girl", "walk"
local A = {"sleeve-inner-back","cape-back","hand-back","arm-back","cape-up-back","leg-back","backpack","boot-ribbon-back","arm-back-path","scarf-back","backpack-pocket","hair-strand-back-3","hair-strand-front-2","neck","leg-front","boot-ribbon-front","base-head","hair-patch","body-dress","collar","ear","underskirt","bag-base","bag-top","eye-front-white","eye-front-iris","bag-strap-front","ribbon-body","sleeve-front","cape-red-down","hair-strand-back-1","hair-strand-front-1","ribbon-shoulder","zip-boy","scarf","hair-side-front","hair-side-transparent","hair-side","hair-bangs","eye-front-eyebrow","nose","eye-front-low-eyelid","hair-bangs-transparent","hat","pompom","cape-blue-shoulder-back","cape-blue-shoulder-front"}
local function fails(set)
  local scene = display.newGroup()
  local obj = C.spine.create(C.data(name, 0.5)); scene:insert(obj)
  obj:setSkin(skin); obj:setAnimation(1, anim, true)
  C.frame(obj); C.mock.endFrame()
  local sg = obj:split(set); scene:insert(sg)
  for f = 1, 5 do C.frame(obj); C.mock.endFrame() end
  obj:reassemble(); C.mock.endFrame()
  local ok = pcall(C.frame, obj); C.mock.endFrame()
  pcall(function() obj:removeSelf() end); display.remove(scene); C.mock.endFrame()
  return not ok
end
assert(fails(A), "does not reproduce")
local cur = A
local changed = true
while changed do
  changed = false
  for i = #cur, 1, -1 do
    local t = {}; for j, s in ipairs(cur) do if j ~= i then t[#t + 1] = s end end
    if #t > 0 and fails(t) then cur = t; changed = true end
  end
end
print(("minimal set (%d slots): {\"%s\"}"):format(#cur, table.concat(cur, "\", \"")))
