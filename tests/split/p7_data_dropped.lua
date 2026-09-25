-- side check: skeleton keeps working after the Lua refs to its atlas + skeleton data are dropped and GC runs
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local function make()
  local atlas = C.spine.loadAtlas("raptor/raptor.atlas")
  local data = C.spine.loadSkeletonData("raptor/raptor.skel", atlas, 0.4)
  return C.spine.create(data)        -- atlas and data go out of scope here
end
local obj = make()
obj:setAnimation(1, "walk", true)
collectgarbage("collect"); collectgarbage("collect")
print("textures released by GC while the skeleton is alive: " .. tostring(C.mock.stats.releaseTexture or 0))
local ok, err = pcall(function() for f = 1, 30 do C.frame(obj); C.mock.endFrame() end end)
print("30 frames after GC: " .. (ok and "ok" or tostring(err)))
C.expect(ok and (C.mock.stats.releaseTexture or 0) == 0, "skeleton broke after its data and atlas were dropped (split-14 on 1.2.5)")
obj:removeSelf(); C.mock.endFrame()
collectgarbage("collect"); collectgarbage("collect"); collectgarbage("collect")
print("after removeSelf + GC: textures released " .. tostring(C.mock.stats.releaseTexture or 0) .. " (the data and atlas are freed once the skeleton is gone)")
C.expect((C.mock.stats.releaseTexture or 0) == 1, "data and atlas not freed after removeSelf + GC")
C.done()
