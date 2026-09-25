-- T8: is a spine object (and its listener closure) ever collected if removeSelf() is never called?
-- (e.g. parent group removed by Composer). luaSelf = registry ref to the SpineSkeleton userdata.
local fx = require("realdata_fixture")
local C = dofile(arg[0]:match("^(.*)/") .. "/check.lua")
local data = fx.loadData("spineboy/spineboy.atlas", "spineboy/spineboy.json")
local weak = setmetatable({}, {__mode = "k"})
do
  for i = 1, 50 do
    local big = string.rep("x", 1e5) .. i -- captured upvalue, 100 KB each
    local fn = function(ev) return big end
    local s = fx.createPlugin(data, fn)
    s:setAnimation(1, "walk", true)
    weak[fn] = true
    weak[s] = true
  end
end
collectgarbage(); collectgarbage()
local nfn, nobj = 0, 0
for k in pairs(weak) do if type(k) == "function" then nfn = nfn + 1 else nobj = nobj + 1 end end
print("after dropping 50 spine objects without removeSelf: listener closures alive =", nfn, " wrapper tables alive =", nobj, " Lua heap KB =", math.floor(collectgarbage("count")))
-- same without a listener: is the SpineSkeleton userdata itself ever collected?
local weak2 = setmetatable({}, {__mode = "k"})
do
  for i = 1, 50 do
    local s = fx.createPlugin(data)
    s:setAnimation(1, "walk", true)
    weak2[rawget(s, "_skeleton")] = true
  end
end
collectgarbage(); collectgarbage()
local nud = 0 for k in pairs(weak2) do nud = nud + 1 end
print("no listener: SpineSkeleton userdata still alive after GC =", nud, "of 50")
C.expect(nfn == 0 and nud == 0, "dropped spine objects and their listeners are never collected (animation-5)")
-- control: harness fx.create (luaSelf left empty) -> collectable
local weak3 = setmetatable({}, {__mode = "k"})
do for i = 1, 50 do local s = fx.create(data); weak3[rawget(s, "_skeleton")] = true end end
collectgarbage(); collectgarbage()
local n3 = 0 for k in pairs(weak3) do n3 = n3 + 1 end
print("control (luaSelf empty): SpineSkeleton userdata alive after GC =", n3, "of 50")
C.done()
