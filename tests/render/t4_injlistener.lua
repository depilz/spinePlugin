-- Injection listener: how often is it called per frame and with which isVisible values?
-- arg[1] "hidden": hide the injected slot and show it again (unsplit); no arg: visible, unsplit then split.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local obj = C.spine.create(C.data("raptor", 0.5))
obj:setAnimation(1, "walk", true)
C.frame(obj)
local order = obj:getDrawOrder()
local slotName = order[math.floor(#order / 2)]
local calls = {}
local marker = display.newRect(0, 0, 10, 10)
obj:inject(marker, slotName, function(e) calls[#calls + 1] = e.isVisible end)

if arg[1] == "hidden" then
  -- one frame's listener calls, e.g. "T", "F" or "" (no call)
  local function frame()
    calls = {}
    C.frame(obj)
    local s = {}
    for i, v in ipairs(calls) do s[i] = v and "T" or "F" end
    return table.concat(s)
  end
  local seen = {}
  local function expectFrames(label, n, want)
    for f = 1, n do
      local got = frame()
      seen[#seen + 1] = got == "" and "-" or got
      C.expect(got == want, ("%s frame %d: listener calls {%s}, expected {%s} (render-8)"):format(label, f, got, want))
    end
  end
  expectFrames("visible", 3, "T")
  obj:setAttachment(slotName, nil)
  expectFrames("hide", 1, "F")
  expectFrames("hidden", 3, "")
  obj:setSlotsToSetupPose()   -- show the slot again (4.3 setAttachment(slot, name) crashes without a skin)
  expectFrames("re-shown", 3, "T")
  print(("slot '%s' visible x3, hidden x4, re-shown x3: %s"):format(slotName, table.concat(seen, " ")))
  -- a listener that removes the skeleton on the hide call: the other listeners of that frame are not called any more
  local obj2 = C.spine.create(C.data("raptor", 0.5))
  obj2:setAnimation(1, "walk", true)
  local late = 0
  obj2:inject(display.newRect(0, 0, 10, 10), slotName, function(e) if not e.isVisible then obj2:removeSelf() end end)
  obj2:inject(display.newRect(0, 0, 10, 10), slotName, function(e) if not e.isVisible then late = late + 1 end end)
  C.frame(obj2)
  obj2:setAttachment(slotName, nil)
  C.frame(obj2)
  print(("removed by a hide listener: later listener calls = %d"):format(late))
  C.expect(late == 0, "listener called after an earlier listener removed the skeleton")
  C.done()
  return
end

for f = 1, 3 do
  calls = {}
  C.frame(obj)
  local s = {}
  for i, v in ipairs(calls) do s[i] = tostring(v) end
  print(("frame %d: slot '%s' (draw-order %d of %d): listener calls = %d -> {%s}"):format(f, slotName, math.floor(#order / 2), #order, #calls, table.concat(s, ", ")))
  C.expect(#calls == 1 and calls[1] == true, "frame " .. f .. ": listener not called exactly once with isVisible=true (render-8)")
end
-- injected object position among group children
for i, c in ipairs(C.mock.children(obj)) do if c == marker then print("marker is child #" .. i .. " of " .. #C.mock.children(obj)) end end
-- Split variant: slot of injection NOT in split; first list is the non-split one
local g = obj:split({ order[#order] })
obj._splitGroup = g
for f = 1, 2 do
  calls = {}
  C.frame(obj)
  local s = {}
  for i, v in ipairs(calls) do s[i] = tostring(v) end
  print(("split frame %d: listener calls = %d -> {%s}"):format(f, #calls, table.concat(s, ", ")))
  C.expect(#calls == 1 and calls[1] == true, "split frame " .. f .. ": listener not called exactly once with isVisible=true (render-8)")
end
C.done()
