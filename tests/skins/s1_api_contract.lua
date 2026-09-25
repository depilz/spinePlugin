-- s1: FINAL skins/attachments API contract (skinsapi). Every row prints what the call did, then PASS/FAIL
-- against the FINAL spec, so on the 1.5.0 bindings most rows FAIL until I7 lands (tests/xfail/4.2.tsv lists them).
-- Assets: goblins.json (skins goblin/goblingirl, linked meshes), hero.json (skin bones), 4.2 exports.
local fx = require("realdata_fixture")
local P = require("skins_probe")
local function gc() for _ = 1, 6 do collectgarbage("collect") end end
local fails, passes = 0, 0
local function show(v)
  if type(v) == "userdata" then local ok, n = pcall(function() return v.name end); return "userdata(" .. tostring(ok and n) .. ")" end
  if type(v) == "table" then return "table#" .. #v end
  return tostring(v)
end
-- run fn protected; returns ok, first result, error text
local function try(fn) local r = { pcall(fn) }; return r[1], r[2], (not r[1]) and tostring(r[2]):gsub("^.-:%d+: ", "") or nil end
local function row(id, what, cond, got)
  if cond then passes = passes + 1 else fails = fails + 1 end
  print(("%s %-5s %-62s -> %s"):format(cond and "PASS" or "FAIL", id, what, got))
end
local function raises(id, what, fn, pattern)
  local ok, v, err = try(fn)
  row(id, what .. " raises", (not ok) and (not pattern or err:find(pattern, 1, true) ~= nil), ok and ("returned " .. show(v)) or ("error: " .. err))
end
local function returns(id, what, fn, pred)
  local ok, v, err = try(fn)
  row(id, what, ok and pred(v), ok and ("returned " .. show(v)) or ("error: " .. err))
end

local ASSETS = dofile(debug.getinfo(1, "S").source:sub(2):match("^(.*/)") .. "assets.lua")
local G = ASSETS.goblins
local data = fx.loadData(G[1], G[2])
local o = fx.create(data)
local o2 = fx.create(data)
dofile(debug.getinfo(1, "S").source:sub(2):match("^(.*/)") .. "group_shim.lua")(o)
local foreign = fx.create(fx.loadData(G[1], G[2]))  -- same files, different SkeletonData

print("== A slot addressing (names and Slot objects; numbers rejected)")
local custom = o:createSkin("custom")
try(function() custom:addSkin("goblin") end)
returns("A1", "skin:getAttachment('head', 'head')", function() return custom:getAttachment("head", "head") end, function(v) return v and v.name == "goblin/head" end)
returns("A2", "skin:getAttachment(o:getSlot('head'), 'head')", function() return custom:getAttachment(o:getSlot("head"), "head") end, function(v) return v and v.name == "goblin/head" end)
returns("A3", "Slot object of another instance, same data", function() return custom:getAttachment(o2:getSlot("head"), "head") end, function(v) return v and v.name == "goblin/head" end)
raises("A4", "skin:getAttachment(<number>, 'head')", function() return custom:getAttachment(5, "head") end, "slot name (string) or Slot object expected")
raises("A5", "skin:getAttachment('nope', 'head')", function() return custom:getAttachment("nope", "head") end, "Slot not found: nope")
raises("A6", "Slot object of another SkeletonData", function() return custom:getAttachment(foreign:getSlot("head"), "head") end, "different skeleton data")
returns("A7", "skin:getAttachment('head', 'missing-key') -> nil", function() return custom:getAttachment("head", "missing-key") end, function(v) return v == nil end)
returns("A8", "skeleton:findSlot('head') returns the Slot", function() return o:findSlot("head") end, function(v) return type(v) == "userdata" and v.name == "head" end)
returns("A9", "skeleton:findSlot('nope') returns nil", function() return o:findSlot("nope") end, function(v) return v == nil end)

print("== B entry records")
returns("B1", "skin:getAttachments()[i] = {slotName, placeholder, attachment}", function()
  local e = custom:getAttachments()[1]; return e end, function(e) return e and type(e.slotName) == "string" and type(e.placeholder) == "string" and e.attachment and e.slotIndex == nil and e.name == nil end)
returns("B2", "head entry: placeholder 'head' vs attachment.name 'goblin/head'", function()
  for _, e in ipairs(custom:getAttachments()) do if e.slotName == "head" then return e end end end,
  function(e) return e and e.placeholder == "head" and e.attachment.name == "goblin/head" end)
returns("B3", "slot:getAttachmentEntries() = {slotName, placeholder, skinName, attachment}", function()
  o:setSkin("goblin"); return o:getSlot("left-hand-item"):getAttachmentEntries() end,
  function(t) local ok = #t >= 2; for _, e in ipairs(t) do ok = ok and e.slotName == "left-hand-item" and e.placeholder and e.skinName and e.attachment and e.slotIndex == nil end; return ok end)
returns("B4", "slot:getAttachmentEntries(<Skin object>)", function() return o:getSlot("head"):getAttachmentEntries(o:findSkin("goblingirl")) end,
  function(t) return #t == 1 and t[1].attachment.name == "goblingirl/head" and t[1].skinName == "goblingirl" end)

print("== C error policy: raise, never false + stderr")
raises("C1", "skin:addSkin('nope')", function() return custom:addSkin("nope") end, "Skin not found: nope")
raises("C2", "skin:addSkin(123)", function() return custom:addSkin(123) end, "skin name (string) or Skin object expected")
raises("C3", "skin:addSkin({})", function() return custom:addSkin({}) end)
raises("C4", "skin:copySkin('nope')", function() return custom:copySkin("nope") end, "Skin not found: nope")
raises("C5", "skin:setAttachment('nope', 'k', att)", function() return custom:setAttachment("nope", "k", o:getSlot("head").attachment) end, "Slot not found: nope")
raises("C6", "skin:setAttachment('head', 'k') (attachment omitted)", function() return custom:setAttachment("head", "k") end)
raises("C7", "skin:removeAttachment('nope', 'k')", function() return custom:removeAttachment("nope", "k") end, "Slot not found")
raises("C8", "skin:findNamesForSlot('nope')", function() return custom:findNamesForSlot("nope") end, "Slot not found")
raises("C9", "slot:setAttachmentFromSkin('nope', 'head')", function() return o:getSlot("head"):setAttachmentFromSkin("nope", "head") end, "Skin not found: nope")
raises("C10", "slot:setAttachmentFromSkin('goblin', 'nope')", function() return o:getSlot("head"):setAttachmentFromSkin("goblin", "nope") end, "not found in skin")
raises("C11", "slot:getSkinAttachments('nope')", function() return o:getSlot("head"):getSkinAttachments("nope") end, "Skin not found")
raises("C12", "slot:getAttachmentEntries('nope')", function() return o:getSlot("head"):getAttachmentEntries("nope") end, "Skin not found")
raises("C13", "skeleton:setSkin('nope') (unchanged)", function() return o:setSkin("nope") end, "Skin not found: nope")
raises("C14", "skin.name = 'x'", function() custom.name = "x" end, "not writable")
raises("C15", "skin.foo = 1", function() custom.foo = 1 end, "not writable")
raises("C16", "slot.foo = 1", function() o:getSlot("head").foo = 1 end, "not writable")
raises("C17", "attachment.foo = 1", function() o:getSlot("head").attachment.foo = 1 end, "not writable")
raises("C18", "mesh attachment .x = 1 (not a region)", function() o:getSlot("head").attachment.x = 1 end, "not writable on a mesh")

print("== D return values of mutators (the skin itself; truthy like 1.5.0's true)")
returns("D1", "skin:addSkin(x) returns the same skin", function() return custom:addSkin("goblingirl") end, function(v) return rawequal(v, custom) end)
returns("D2", "chaining createSkin():addSkin():addSkin()", function() return o:createSkin("c"):addSkin("goblin"):addSkin("goblingirl") end, function(v) return v and v.name == "c" end)
returns("D3", "slot:setAttachmentFromSkin returns the slot", function() local s = o:getSlot("head"); return s:setAttachmentFromSkin("goblin", "head") == s end, function(v) return v == true end)

print("== E share vs copy")
local dagger
for _, e in ipairs(o:getSlot("left-hand-item"):getAttachmentEntries("default")) do if e.placeholder == "dagger" then dagger = e.attachment end end
local gear = o:createSkin("gear")
returns("E1", "skin:setAttachment stores the same object (shared)", function()
  gear:setAttachment("right-hand-item", "dagger", dagger); return gear:getAttachment("right-hand-item", "dagger") == dagger end, function(v) return v == true end)
returns("E2", "attachment:copy() is a new object", function() return dagger:copy() ~= dagger end, function(v) return v == true end)
returns("E3", "retint a copy leaves the original", function()
  local c = dagger:copy(); c.color = { g = 0.2 }; gear:setAttachment("right-hand-item", "red-dagger", c)
  return dagger.color.g, gear:getAttachment("right-hand-item", "red-dagger").color.g end, function(v) return v == 1 end)
returns("E4", "mesh copy keeps its deform timeline link (probe)", function()
  local head = o:findSkin("goblin"):getAttachment("head", "head"); local c = head:copy()
  return select(3, P.meshInfo(c)) == P.ptr(head) end, function(v) return v == true end)

print("== F findSkin / getSkin")
o:setSkin("goblin")
returns("F1", "findSkin('goblingirl') returns it without applying", function() local s = o:findSkin("goblingirl"); return s and s.name == "goblingirl" and o:getSkin().name == "goblin" end, function(v) return v == true end)
returns("F2", "findSkin('nope') -> nil", function() return o:findSkin("nope") end, function(v) return v == nil end)
raises("F3", "getSkin('goblingirl')", function() return o:getSkin("goblingirl") end, "takes no argument")
raises("F4", "getSkin(nil)", function() return o:getSkin(nil) end, "takes no argument")
returns("F5", "getSkin() returns the applied skin", function() return o:getSkin() end, function(v) return v and v.name == "goblin" end)

print("== G data skins are read-only; custom skins are mutable")
raises("G1", "findSkin('goblin'):removeAttachment('head','head')", function() return o:findSkin("goblin"):removeAttachment("head", "head") end, "read-only")
raises("G2", "findSkin('goblin'):setAttachment('head','x',att)", function() return o:findSkin("goblin"):setAttachment("head", "x", dagger) end, "read-only")
raises("G3", "getSkin() (applied data skin):addSkin('goblingirl')", function() return o:getSkin():addSkin("goblingirl") end, "read-only")
raises("G4", "findSkin('default'):removeAttachment(...)", function() return o:findSkin("default"):removeAttachment("left-hand-item", "dagger") end, "read-only")
raises("G5", "findSkin('goblin').color = {...}", function() o:findSkin("goblin").color = { r = 0 } end, "read-only")
returns("G6", "data skin still intact (head entry present)", function() return o:findSkin("goblin"):getAttachment("head", "head") end, function(v) return v ~= nil end)
returns("G7", "custom skin mutable (removeAttachment)", function() return custom:removeAttachment("head", "head") end, function(v) return rawequal(v, custom) end)
returns("G8", "getSkin() of an applied CUSTOM skin (wrappers GC'd) stays mutable", function()
  do local t = o:createSkin("t"); t:addSkin("goblin"); o:setSkin(t) end; gc()
  local w = o:getSkin(); w:removeAttachment("head", "head"); return w.name end, function(v) return v == "t" end)

print("== H setSkin(nil)")
returns("H1", "setSkin(nil): no skin, only default-skin attachments", function()
  o:setSkin("goblin"); o:setSkin(nil); local a = fx.slotAttachments(o)
  return o:getSkin() == nil and a.head == false and a.torso == false and a["left-hand-item"] == "spear" end, function(v) return v == true end)
returns("H2", "setSkin(nil, false): slots keep attachments", function()
  o:setSkin("goblin"); o:setSkin(nil, false); local a = fx.slotAttachments(o); return o:getSkin() == nil and a.head == "goblin/head" end, function(v) return v == true end)
returns("H3", "setSkin(nil) releases the applied custom skin", function()
  do local s = o:createSkin("tmp"); s:addSkin("goblin"); o:setSkin(s) end
  gc(); local before = P.appliedOwner(o); o:setSkin(nil); gc(); local after = P.appliedOwner(o)
  return tostring(before) .. " -> " .. tostring(after) end, function(v) return v:find("-> nil", 1, true) ~= nil end)
local hero = fx.create(fx.loadData(ASSETS.hero[1], ASSETS.hero[2]))
returns("H4", "hero: setSkin('weapon/sword') then setSkin(nil) deactivates skin bone", function()
  hero:setSkin("weapon/sword"); local a = fx.activeBones(hero)["weapon-sword"]; hero:setSkin(nil); local b = fx.activeBones(hero)["weapon-sword"]
  return tostring(a) .. "," .. tostring(b) end, function(v) return v == "true,false" end)
raises("H5", "setSkin() (no argument)", function() return o:setSkin() end)

print("== I removed API")
-- (the harness object has no Solar2D group fallback, so probe the method table directly)
returns("I1", "skeleton method table has no registerSkin", function() return rawget(getmetatable(o), "registerSkin") end, function(v) return v == nil end)
returns("I2", "slot.attachmentLocked reads nil", function() return o:getSlot("head").attachmentLocked end, function(v) return v == nil end)
raises("I3", "slot.attachmentLocked = true", function() o:getSlot("head").attachmentLocked = true end, "not writable")

print("== J __eq on Skin / Attachment / Slot")
o:setSkin(custom)
returns("J1", "getSkin() == custom", function() return o:getSkin() == custom end, function(v) return v == true end)
returns("J2", "findSkin('goblin') == findSkin('goblin')", function() return o:findSkin("goblin") == o:findSkin("goblin") end, function(v) return v == true end)
returns("J3", "slot.attachment == slot.attachment", function() local s = o:getSlot("torso"); return s.attachment == s.attachment end, function(v) return v == true end)
returns("J4", "getSlot('head') == slots[i] of the same instance", function()
  for _, s in ipairs(o.slots) do if s.name == "head" then return s == o:getSlot("head") end end end, function(v) return v == true end)
returns("J5", "same slot name on another instance is not equal", function() return o:getSlot("head") == o2:getSlot("head") end, function(v) return v == false end)
returns("J6", "custom ~= data skin", function() return custom == o:findSkin("goblin") end, function(v) return v == false end)

print("== K Skin objects accepted wherever a skin is expected")
returns("K1", "slot:setAttachmentFromSkin(<Skin>, 'head')", function() local s = o:getSlot("head"); s:setAttachmentFromSkin(o:findSkin("goblingirl"), "head"); return s.attachment.name end, function(v) return v == "goblingirl/head" end)
returns("K2", "slot:getSkinAttachments(<Skin>)", function() return #o:getSlot("head"):getSkinAttachments(o:findSkin("goblin")) end, function(v) return v == 1 end)
raises("K3", "slot:setAttachmentFromSkin(<foreign Skin>, 'head')", function() return o:getSlot("head"):setAttachmentFromSkin(foreign:findSkin("goblin"), "head") end, "different skeleton data")

print("== L region geometry setters take effect")
returns("L1", "dagger copy .x += 100 moves world vertices", function()
  local s = o:getSlot("left-hand-item"); local c = dagger:copy(); s.attachment = c; fx.worldTransform(o)
  local v1 = c:computeWorldVertices(s)[1]; c.x = c.x + 100; local v2 = c:computeWorldVertices(s)[1]
  return math.abs(v2 - v1) end, function(v) return v > 1 end)

print("== M skin:clear() (in-place refill)")
returns("M1", "clear() empties entries, bones, constraints and returns the skin", function()
  local h = hero:createSkin("h"):addSkin("weapon/sword"):addSkin("weapon/morningstar")
  local before = #h:getBones(); local r = h:clear()
  return rawequal(r, h) and before > 0 and #h:getBones() == 0 and #h:getConstraints() == 0 and #h:getAttachments() == 0 end, function(v) return v == true end)
returns("M2", "clear()+refill of the APPLIED skin + setSkin(same) = fresh build", function()
  local s = hero:createSkin("h2"):addSkin("weapon/morningstar"); hero:setSkin(s)
  s:clear():addSkin("weapon/sword"); hero:setSkin(s)
  local b = fx.activeBones(hero); return tostring(b["weapon-sword"]) .. "," .. tostring(b["weapon-morningstar"]) end, function(v) return v == "true,false" end)
raises("M3", "findSkin('goblin'):clear()", function() return o:findSkin("goblin"):clear() end, "read-only")
print(("== s1 summary: %d PASS, %d FAIL"):format(passes, fails))
fx.dispose(o); fx.dispose(o2); fx.dispose(foreign); fx.dispose(hero)
custom, gear, dagger = nil, nil, nil
gc()
