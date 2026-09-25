local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local obj = C.spine.create(C.data(arg[1] or "raptor", 0.5)); obj:setAnimation(1, "walk", true); C.frame(obj)
local t = {}
for i, d in ipairs(obj:getDrawOrder()) do t[#t + 1] = i .. ":" .. d .. "=" .. tostring(C.fx.attachmentKind(obj, d)) end
print(table.concat(t, " "))
