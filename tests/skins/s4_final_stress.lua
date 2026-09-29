-- s4: randomized stress of the skins API under ASan (adapted from gap-5 b3_share_stress.lua).
-- Shared attachments (data, custom, :copy()) stored in custom skins under random placeholders, addressed by slot
-- name or Slot object; skin:clear() refills of an applied skin; removal while displayed; setSkin(nil / other / same,
-- reset or not); read-only data-skin mutations must raise; findSkin wrappers; skeletons disposed or dropped;
-- about half the holders stay alive into lua_close. Usage: s4_final_stress.lua <seed>. Fails on an unexpected success.
local fx = require("realdata_fixture")
local function gc() collectgarbage("collect"); collectgarbage("collect") end
math.randomseed(tonumber(arg and arg[1]) or 7)
local ASSETS = dofile(debug.getinfo(1, "S").source:sub(2):match("^(.*/)") .. "assets.lua")
local sets = {
  { fx.loadData(ASSETS.goblins[1], ASSETS.goblins[2]), "walk" },
  { fx.loadData(ASSETS.dragon[1], ASSETS.dragon[2]), "flying" },
  { fx.loadData(ASSETS.mix[1], ASSETS.mix[2]), "walk" },
}
local keep, nOps, nRaised, nUnexpected = {}, 0, 0, 0
local function mustRaise(fn) local ok = pcall(fn); if ok then nUnexpected = nUnexpected + 1 else nRaised = nRaised + 1 end end
for cycle = 1, 150 do
  local set = sets[math.random(#sets)]
  local o = fx.create(set[1])
  local skins = o:getSkins()
  local custom = o:createSkin("c" .. cycle):addSkin(skins[math.random(#skins)])
  local dataSkin = o:findSkin(skins[math.random(#skins)])
  if math.random() < 0.3 then mustRaise(function() dataSkin:removeAttachment(o:getSlotNames()[1], "x") end) end
  if math.random() < 0.3 then mustRaise(function() dataSkin:addSkin(custom) end) end
  local slots = o.slots
  local pool = {}
  for _ = 1, 8 do
    local sl = slots[math.random(#slots)]
    local entries = sl:getAttachmentEntries(skins[math.random(#skins)])
    if #entries > 0 then
      local e = entries[math.random(#entries)]
      local att = e.attachment
      if math.random() < 0.3 then att = att:copy() end
      pool[#pool + 1] = att
      local key = (math.random() < 0.5) and e.placeholder or ("k" .. math.random(3))
      local slotArg = (math.random() < 0.5) and sl or sl.name
      custom:setAttachment(slotArg, key, att); nOps = nOps + 1
      if math.random() < 0.3 then custom:setAttachment(slotArg, key, att) end        -- re-put same object
    end
  end
  o:setSkin(custom, math.random() < 0.5)
  o:setAnimation(1, set[2], true)
  for _ = 1, 3 do o:updateState(50); fx.worldTransform(o) end
  -- display pooled/entry attachments, then remove random entries (possibly displayed)
  for _ = 1, 3 do
    local sl = slots[math.random(#slots)]
    for _, e in ipairs(sl:getAttachmentEntries(custom)) do
      if math.random() < 0.5 then sl.attachment = e.placeholder end
      if math.random() < 0.5 then custom:removeAttachment(sl, e.placeholder) end
    end
  end
  if #pool > 0 and math.random() < 0.3 then slots[math.random(#slots)].attachment = pool[math.random(#pool)] end
  for _ = 1, 3 do o:updateState(50); fx.worldTransform(o) end
  -- in-place refill of the applied skin (clear while its attachments are displayed)
  if math.random() < 0.5 then
    custom:clear():addSkin(skins[math.random(#skins)])
    if #pool > 0 then custom:setAttachment(slots[1], "p", pool[1]) end
    o:setSkin(custom, math.random() < 0.5)
  end
  for _ = 1, 2 do o:updateState(50); fx.worldTransform(o) end
  local r0 = math.random()
  if r0 < 0.2 then o:setSkin(nil, math.random() < 0.5)
  elseif r0 < 0.6 then o:setSkin(skins[math.random(#skins)], math.random() < 0.5) end
  for _ = 1, 2 do o:updateState(50); fx.worldTransform(o) end
  local r = math.random()
  if r < 0.35 then fx.dispose(o)
  elseif r < 0.7 then keep[#keep + 1] = { o = o, skin = (math.random() < 0.5) and custom or nil, att = pool[1], data = dataSkin }
  else keep[#keep + 1] = { att = pool[#pool], skin = (math.random() < 0.3) and custom or nil, slot = slots[1] } end
  o, custom, pool, slots, dataSkin = nil, nil, nil, nil, nil
  if cycle % 7 == 0 then gc() end
  if cycle % 25 == 0 then
    for i = #keep, 1, -1 do if math.random() < 0.3 then table.remove(keep, i) end end; gc()
    -- use stale Slot holders of disposed skeletons as a slot argument under pcall (exercised for sanitizers, not asserted)
    for _, k in ipairs(keep) do if k.slot and k.skin then pcall(function() k.skin:getAttachment(k.slot, "x") end) end end
  end
end
print(("s4 done; %d setAttachment calls, %d expected raises, %d unexpected successes, %d holders alive at lua_close")
  :format(nOps, nRaised, nUnexpected, #keep))
assert(nUnexpected == 0, ("%d read-only data-skin mutations did not raise"):format(nUnexpected))
