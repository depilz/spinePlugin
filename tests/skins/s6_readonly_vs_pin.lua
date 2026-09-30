-- s6: every Lua path that could drop a data-skin reference raises, so a Deform/Sequence timeline attachment can no
-- longer be freed from Lua (the v43 t2 / gap-5 a2 scenario) and no timeline pin is needed: the fixture's
-- SkeletonDataHolder carries none. Fails unless the case's entry is its animation's Deform/Sequence timeline attachment,
-- every attempt raises, the entry survives, and teardown frees all.
local fx = require("realdata_fixture")
local P = require("skins_probe")
local W = debug.getinfo(1, "S").source:sub(2):match("^(.*/)")
local ASSETS = dofile(W .. "assets.lua")
local function fullgc() for _ = 1, 4 do collectgarbage("collect") end end
local SEQ = ASSETS.sequence
local cases = {
  { name = "goblins walk (deform on default 'dagger')", files = ASSETS.goblins, skin = "default", slot = "right-hand-item", key = "dagger", anim = "walk", kind = "deform" },
  { name = ("%s %s (sequence on '%s')"):format(SEQ[2]:match("([^/]+)%.json$"), SEQ.anim, SEQ.key), files = SEQ, skin = "default", slot = SEQ.slot, key = SEQ.key, anim = SEQ.anim, kind = "sequence" },
}
-- keyedBy(o, c, att): true when a c.kind timeline of animation c.anim holds att
local function keyedBy(o, c, att)
  for _, t in ipairs(fx.timelineAttachments(o)) do
    if t.anim == c.anim and t.kind == c.kind and t.ptr == P.ptr(att) then return true end
  end
  return false
end
local function run(c)
  local data = fx.loadData(c.files[1], c.files[2])
  local o = fx.create(data)
  dofile(W .. "group_shim.lua")(o)
  o:setSkin(c.skin)
  local slot = o:getSlot(c.slot)
  local timeline = keyedBy(o, c, o:findSkin(c.skin):getAttachment(c.slot, c.key))
  slot.attachment = nil
  local other = o:findSkin(c.skin):getAttachments()[1].attachment
  local attempts = {
    { "getSkin():removeAttachment", function() o:getSkin():removeAttachment(c.slot, c.key) end },
    { "findSkin():removeAttachment", function() o:findSkin(c.skin):removeAttachment(c.slot, c.key) end },
    { "findSkin():setAttachment (replace)", function() o:findSkin(c.skin):setAttachment(c.slot, c.key, other) end },
    { "findSkin():setAttachment(nil)", function() o:findSkin(c.skin):setAttachment(c.slot, c.key, nil) end },
    { "findSkin():clear()", function() o:findSkin(c.skin):clear() end },
    { "skeleton:registerSkin (removed)", function() o:registerSkin(o:createSkin("r")) end },
  }
  local raised = 0
  for _, a in ipairs(attempts) do local ok = pcall(a[2]); if not ok then raised = raised + 1 end end
  fullgc()
  o:setAnimation(1, c.anim, true)
  for _ = 1, 30 do o:updateState(1000 / 30); fx.worldTransform(o) end
  local entry = o:findSkin(c.skin):getAttachment(c.slot, c.key)
  print(("%s: %s timeline attachment: %s; %d/%d mutation attempts raised; entry still present: %s; animation applied 30 frames: ok")
    :format(c.name, c.kind, tostring(timeline), raised, #attempts, tostring(entry ~= nil)))
  fx.dispose(o)
  assert(timeline, ("%s: the entry is not a %s timeline attachment of '%s'"):format(c.name, c.kind, c.anim))
  assert(raised == #attempts and entry ~= nil, c.name .. ": a data-skin mutation did not raise or dropped the entry")
end
for _, c in ipairs(cases) do run(c) end
fullgc()
local created, freed = fx.dataStats()
print(("teardown: data created %d freed %d, spine heap %d B"):format(created, freed, fx.usedMemory()))
assert(created == freed and fx.usedMemory() == 0, "teardown left spine memory behind")
