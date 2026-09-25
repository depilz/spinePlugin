-- renderCommands pops the Lua stack for commands with numIndices < 3 even though nothing was pushed.
-- Reachable when the first command of a list is empty: injection into a slot whose region attachment alpha is 0
-- (vendored SkeletonRenderer creates a 0-index "dummy" command), or a fully clipped first attachment.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local mock = C.mock
local function firstRegionSlot(obj)
  for _, name in ipairs(obj:getDrawOrder()) do
    local s = obj:getSlot(name)
    local a = s.attachment
    if a then return s, a end
  end
end
for _, case in ipairs({ {"raptor", 1}, {"spineboy", 1}, {"goblins", 1, "goblin"} }) do
  local name = case[1]
  local obj = C.spine.create(C.data(name, 0.5))
  if case[3] then obj:setSkin(case[3]) end
  obj:setAnimation(1, obj:getAnimations()[case[2]], true)
  C.frame(obj)
  local slot, att = firstRegionSlot(obj)
  print(("%s: first drawn slot '%s' attachment '%s' (%s)"):format(name, slot.name, att.name, att.type))
  local marker = display.newRect(0, 0, 10, 10)
  obj:inject(marker, slot.name)
  C.frame(obj)
  print("  inject into it, draw: ok, oracle errors:", #C.check(obj, name))
  att.color = { a = 0 }       -- public API: hide the placeholder attachment by its colour alpha
  local ok, err = pcall(C.frame, obj)
  print("  after attachment.color = {a=0}: draw ok?", ok, err and ("error: " .. tostring(err)) or "")
  local ok2, err2 = pcall(C.frame, obj)
  print("  next frame: ok?", ok2, err2 and ("error: " .. tostring(err2)) or "")
  C.expect(ok and ok2, name .. ": draw fails after hiding the injected slot's attachment (render-2)")
end
C.done()
