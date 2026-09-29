-- obj.fill userdata: Lua heap per read after full GC (render-10 leak census).
-- t7_fill.lua [reads] [uaf]: "uaf" also writes through the fill proxy after removeSelf + GC, which must raise.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local obj = C.spine.create(C.data("raptor", 0.5))
local function gc() collectgarbage("collect"); collectgarbage("collect") end
gc(); local k0 = collectgarbage("count")
local N = tonumber(arg and arg[1]) or 100000
for i = 1, N do local a = obj.fill.a end        -- e.g. reading obj.fill.a every frame
gc(); local k1 = collectgarbage("count")
local reg = 0; for _ in pairs(debug.getregistry()) do reg = reg + 1 end
print(("after %d reads of obj.fill: Lua heap +%.1f KB after full GC (%.1f bytes/read); registry entries=%d"):format(N, k1 - k0, (k1 - k0) * 1024 / N, reg))
C.expect((k1 - k0) * 1024 / N < 1, "obj.fill reads leak after full GC (render-10)")
if arg[2] == "uaf" then
  local f = obj.fill
  obj:removeSelf(); obj = nil
  gc()
  local ok, err = pcall(function() f.r = 0.5 end)
  print("removed skeleton + GC; f.r = 0.5: ok=", ok, err or "")
  C.expect(not ok and tostring(err):find("Fill belongs to a removed skeleton", 1, true),
    "fill write after removeSelf raises (render-10)")
end
C.done()
