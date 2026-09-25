-- trace group:insert calls around the hidden-injection frame (raptor-horn-back), to explain release-14
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock, fx = C.mock, C.fx
local obj = C.spine.create(C.data("raptor", 0.5))
local marker = display.newRect(0, 0, 1, 1)
local function name(o) if o == marker then return "MARKER" end return tostring(mock.vertexCount(o)) end
local function kids() local t = {}; for _, ch in ipairs(mock.children(obj)) do t[#t + 1] = name(ch) end; return table.concat(t, "|") end
mock.onInsert = function(g, a, b) if g == obj then io.write(("   insert(%s, %s)"):format(tostring(b and a or "end"), name(b or a))) end end
obj:setAnimation(1, "walk", true)
io.write("frame0:"); C.frame(obj); print("  -> " .. kids())
local sname = arg[1] or "raptor-horn-back"
obj:inject(marker, sname)
io.write("visible:"); obj:draw(); print("  -> " .. kids())
fx.setAttachmentAlpha(obj, sname, 0)
io.write("hidden d1:"); obj:draw(); print("  -> " .. kids())
