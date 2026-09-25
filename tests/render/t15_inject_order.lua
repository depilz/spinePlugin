-- Is an injected object placed right after its slot's mesh? (checked for every slot of raptor, 1 injection at a time)
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock = C.mock
local bad, total = 0, 0
local obj = C.spine.create(C.data("raptor", 0.5))
obj:setAnimation(1, "walk", true)
C.frame(obj)
for idx, s in ipairs(obj.slots) do
  local marker = display.newRect(0, 0, 1, 1)
  obj:inject(marker, s.name)
  C.frame(obj)
  local cmds = C.fx.expected(obj)
  local want
  local n = 0
  for _, c in ipairs(cmds) do
    if c.numIndices >= 3 then n = n + 1 end
    if c.injectionSlot == idx - 1 then want = n end
  end
  if want then
    total = total + 1
    local got = 0
    for _, ch in ipairs(mock.children(obj)) do if ch == marker then break end; if mock.kind(ch) == "mesh" then got = got + 1 end end
    if got ~= want then bad = bad + 1; print(("slot %s: marker after %d meshes, expected after %d"):format(s.name, got, want)) end
  end
  obj:eject(marker)
end
local errs = C.check(obj, "raptor")
print(("injection placement checks: %d slots with a drawn command, %d misplaced; oracle errors now: %d"):format(total, bad, #errs))
C.expect(bad == 0 and #errs == 0, "injected objects misplaced")
C.done()
