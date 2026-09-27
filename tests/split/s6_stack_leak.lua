-- s6: render-13 (draw with extra arguments in split mode) and render-11 (native heap growth per split draw).
-- arg[1] selects the case (drawargs, leak); no arg = both. The leak case needs the counting operator new (splitfx.cpp).
local C = dofile(arg[0]:match("^(.*)/") .. "/../splitfx/common.lua")
local mock = C.mock
local which = arg[1]
local scene = display.newGroup()
local obj = C.spine.create(C.data("raptor", 0.5)); scene:insert(obj)
obj:setAnimation(1, "walk", true)
local sg
local function draw(...) obj:updateState(16); obj:draw(...) end
if not which or which == "drawargs" then
  sg = obj:split({ "raptor-body", "raptor-horn" }); scene:insert(sg)
  local r = {}
  for _, case in ipairs({ { "draw()", {} }, { "draw(event table)", { { name = "enterFrame" } } }, { "draw(1, 2)", { 1, 2 } } }) do
    obj:split({ "raptor-front-leg", "raptor-horn", "raptor-body", "raptor-back-arm" }) -- forces re-inserts
    local ok, err = pcall(draw, unpack(case[2])); mock.endFrame()
    local e = ok and C.check(obj, sg, nil, case[1]) or {}
    obj:split({ "raptor-body", "raptor-horn" }); pcall(draw); mock.endFrame()
    r[#r + 1] = ("%s: %s"):format(case[1], ok and ("ok, oracle " .. (#e == 0 and "ok" or e[1])) or ("raised " .. tostring(err):gsub("^.-ENGINE", "ENGINE"):sub(1, 100)))
    C.expect(ok and #e == 0, case[1] .. " after a re-split (render-13)")
  end
  print("render-13 re-split then " .. table.concat(r, " | "))
  local ok, err = pcall(obj.reassemble, obj, "extra", 42); mock.endFrame()
  print("reassemble(extra args): " .. (ok and "ok" or tostring(err)))
  C.expect(ok, "reassemble(extra args)")
end
if which == "drawargs" then C.done(); return end
-- render-11: native heap growth per draw, unsplit vs split
local function measure(label, N)
  collectgarbage("collect")
  local c0, b0, t0 = C.fx.newStats()
  for f = 1, N do C.frame(obj); mock.endFrame() end
  collectgarbage("collect")
  local c1, b1, t1 = C.fx.newStats()
  C.expect(t1 > t0, label .. ": operator new is not counted in this build")
  C.expect(c1 == c0, label .. ": native heap grows per draw (render-11)")
  return ("%s %d frames: live operator-new blocks %+d (%+d bytes)"):format(label, N, c1 - c0, b1 - b0)
end
for f = 1, 10 do C.frame(obj); mock.endFrame() end
local a = measure("unsplit", 1000)
sg = obj:split({ "raptor-body", "raptor-horn" }); scene:insert(sg)
for f = 1, 10 do C.frame(obj); mock.endFrame() end
print("render-11 " .. a .. " | " .. measure("split", 1000))
C.done()
