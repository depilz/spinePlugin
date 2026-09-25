-- search: split(A) [-> split(B)] -> frames -> reassemble() -> does the next draw raise? (mesh left in the removed split group)
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local name, resplit = arg[1] or "celestial-circus", arg[2] == "resplit"
local found, N = 0, 300
for trial = 1, N do
  math.randomseed(trial * 104729)
  local scene = display.newGroup()
  local obj = C.spine.create(C.data(name, 0.5)); scene:insert(obj)
  if name == "mix-and-match" then obj:setSkin("full-skins/girl") end
  local anims = {}
  for _, a in ipairs(obj:getAnimations()) do if a ~= "portal" then anims[#anims + 1] = a end end
  local a = anims[math.random(#anims)]
  obj:setAnimation(1, a, true)
  C.frame(obj); C.mock.endFrame()
  local slots = C.slotNames(obj)
  local function rnd() local t = {}; for _, s in ipairs(slots) do if math.random() < 0.5 then t[#t + 1] = s end end; return t end
  local A, B = rnd(), rnd()
  local sg = obj:split(A); scene:insert(sg)
  for f = 1, 5 do C.frame(obj); C.mock.endFrame() end
  if resplit then obj:split(B); for f = 1, 5 do C.frame(obj); C.mock.endFrame() end end
  obj:reassemble(); C.mock.endFrame()
  local ok, err = pcall(C.frame, obj); C.mock.endFrame()
  if not ok then
    found = found + 1
    if found == 1 then print(("  e.g. trial %d anim=%s A={%s}%s: %s"):format(trial, a, table.concat(A, ","), resplit and (" B={" .. table.concat(B, ",") .. "}") or "", tostring(err))) end
  end
  pcall(function() obj:removeSelf() end); display.remove(scene); C.mock.endFrame()
end
print(("%-16s %s: %d of %d cycles broke the next draw after reassemble()"):format(name, resplit and "split,re-split,reassemble" or "split,reassemble", found, N))
