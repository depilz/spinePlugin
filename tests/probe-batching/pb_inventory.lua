-- probe-batching: inventory of example skeletons (skins, animations, slots)
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local names = { "alien","celestial-circus","chibi-stickers","cloud-pot","coin","dragon","goblins","hero","mix-and-match","owl","powerup","raptor","sack","snowglobe","speedy","spineboy","stretchyman","tank","vine","windmill" }
for _, n in ipairs(names) do
  local ok, d = pcall(C.data, n, 0.5)
  if not ok then print(n, "LOAD FAIL", tostring(d):sub(1,100)) else
    local obj = C.spine.create(d)
    local sk = obj:getSkins(); local skn = {}
    for i, s in ipairs(sk) do skn[#skn+1] = type(s) == "string" and s or (s.name or tostring(s)) end
    print(("%-17s slots=%3d anims=%2d skins=%2d first=%s"):format(n, #obj:getSlotNames(), #obj:getAnimations(), #skn, table.concat(skn, ",", 1, math.min(3, #skn))))
    obj:removeSelf(); C.mock.endFrame()
  end
end
