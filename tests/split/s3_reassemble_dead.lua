-- render-7 consequence: split -> reassemble (the documented flow) leaves a mesh inside the split group; reassemble()
-- removes the group, so that mesh is finalized at the end of the frame and every later draw() raises.
-- Minimal set found by p4_minimize.lua (mix-and-match, full-skins/girl, walk).
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock = C.mock
local scene = display.newGroup()
local obj = C.spine.create(C.data("mix-and-match", 0.5)); scene:insert(obj)
obj:setSkin("full-skins/girl"); obj:setAnimation(1, "walk", true)
C.frame(obj); mock.endFrame()
local set = { "hand-back", "arm-back", "leg-back", "sleeve-front" }
local sg = obj:split(set); scene:insert(sg)
local bad = 0
for f = 1, 5 do C.frame(obj); mock.endFrame(); if #C.check(obj, sg, nil, "") > 0 then bad = bad + 1 end end
local inSplit = 0; for _, c in ipairs(mock.children(sg)) do if mock.kind(c) == "mesh" then inSplit = inSplit + 1 end end
print(("split({%s}): 5 frames, oracle-bad frames=%d, meshes in split group=%d"):format(table.concat(set, ","), bad, inSplit))
obj:reassemble()
local left = 0; for _, c in ipairs(mock.children(sg)) do if mock.kind(c) == "mesh" then left = left + 1 end end
print(("reassemble(): meshes still inside the (now removed) split group: %d; draw in the same frame: %s"):format(left, tostring((pcall(C.frame, obj)))))
mock.endFrame()
local fails = 0; local msg
for f = 1, 10 do local ok, err = pcall(C.frame, obj); mock.endFrame(); if not ok then fails = fails + 1; msg = msg or err end end
print(("next 10 frames: draw() raised %d times%s"):format(fails, msg and (": " .. tostring(msg)) or ""))
local e = C.check(obj, nil, nil, "after")
print("oracle after: " .. (#e == 0 and "ok" or e[1]))
C.expect(fails == 0 and #e == 0, "draw() after reassemble() raises on a mesh left in the removed split group (render-7)")
C.done()
