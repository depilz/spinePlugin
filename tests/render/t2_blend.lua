-- Blend mode lost when a reused mesh changes texture (Solar2D resets the Paint on `fill = {...}`).
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock = C.mock
local obj = C.spine.create(C.data("snowglobe", 0.5))
obj:setAnimation(1, "idle", true)
C.frame(obj); C.frame(obj)
local before = #C.check(obj, "snowglobe")
print("before swap, oracle errors:", before)
C.expect(before == 0, "oracle errors before the texture swap")
local shadow = obj:getSlot("globe-shadow")
ONPAGE1 = {}
do local page
  for line in io.lines("snowglobe/snowglobe.atlas") do
    if line:match("%.png$") then page = line elseif line:match("^[^%s]") and not line:find(":") and page == "snowglobe.png" then ONPAGE1[line] = true end
  end
end
-- find a region attachment of another slot that lives on another page
local donor
for _, s in ipairs(obj.slots) do
  local a = s.attachment
  if a and a.type == "region" and s.name ~= "globe-shadow" and ONPAGE1[a.name] then
    donor = donor or a
  end
end
print("globe-shadow attachment:", shadow.attachment and shadow.attachment.name, "donor:", donor and donor.name)
shadow.attachment = donor
C.frame(obj)
local errs = C.check(obj, "snowglobe")
print("after swap, oracle errors:", #errs)
for i = 1, #errs do print("  " .. errs[i]) end
C.expect(#errs == 0, "blend mode lost after the texture swap (render-6)")
-- show the mesh that should be multiply
for i, m in ipairs(mock.children(obj)) do
  local p = mock.paint(m)
  if p and p.spec and p.spec.filename and m and mock.kind(m) == "mesh" then
    if p.blendMode ~= "normal" then print("  mesh", i, p.spec.filename, p.blendMode) end
  end
end
C.done()
