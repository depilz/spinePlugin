-- split()/reassemble(): are meshes placed in the right group, and does drawing continue to work?
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock = C.mock
local seed = tonumber(arg and arg[1]) or 1
local totalBad, totalFrames, errorsRaised = 0, 0, 0
local firstBad
for run = 1, 30 do
  math.randomseed(seed * 1000 + run)
  local obj = C.spine.create(C.data("raptor", 0.5))
  local anims = obj:getAnimations()
  obj:setAnimation(1, anims[math.random(#anims)], true)
  C.frame(obj)
  local function randomSlots()
    local t = {}
    for _, s in ipairs(obj.slots) do if math.random() < 0.5 then t[#t + 1] = s.name end end
    return t
  end
  local ok, err = pcall(function()
    local g = obj:split(randomSlots()); obj._splitGroup = g
    for phase = 1, 3 do
      for f = 1, 20 do
        C.frame(obj); totalFrames = totalFrames + 1
        local e = C.check(obj, "raptor run " .. run .. " phase " .. phase)
        if #e > 0 then totalBad = totalBad + 1; firstBad = firstBad or e[1]; badBy = badBy or {}; local k = run .. ":" .. phase; if not badBy[k] then badBy[k] = 0; print("run " .. run .. " phase " .. phase .. " frame " .. f .. ": " .. table.concat(e, " | "):sub(1, 300)) end; badBy[k] = badBy[k] + 1 end
      end
      if phase == 1 then obj:split(randomSlots()) end        -- re-split with another slot set
      if phase == 2 then obj:reassemble(); obj._splitGroup = nil end
    end
  end)
  if not ok then errorsRaised = errorsRaised + 1; print("run " .. run .. " raised: " .. tostring(err)) end
end
print(("frames checked=%d, frames with wrong group contents=%d, runs raising errors=%d"):format(totalFrames, totalBad, errorsRaised))
if firstBad then print("first mismatch: " .. firstBad) end
C.expect(totalBad == 0 and errorsRaised == 0, "meshes in the wrong group after split/re-split/reassemble (render-7)")
C.done()
