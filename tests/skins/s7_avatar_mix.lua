-- s7: the avatar recipe on the public mix-and-match skeleton, so it runs on both lines' exports unchanged.
-- Usage: s7_avatar_mix.lua <avatars> <rebuilds> <mode: find|inplace>. Fails on a fresh-build mismatch, a spine heap
-- after full GC outside the band (find: within +-70 KB of the warm baseline; inplace: at most +300 KB) or a teardown
-- that leaves data or spine memory behind.
local fx = require("realdata_fixture")
local ASSETS = dofile(debug.getinfo(1, "S").source:sub(2):match("^(.*/)") .. "assets.lua")
local N = tonumber(arg and arg[1]) or 60
local REBUILDS = tonumber(arg and arg[2]) or 1000
local MODE = arg and arg[3] or "find"
local DT = 1000 / 60
local function fullgc() for _ = 1, 4 do collectgarbage("collect") end end

local data = fx.loadData(ASSETS.mix[1], ASSETS.mix[2])
local probe = fx.create(data)
local ORDER = { "nose", "eyes", "hair", "clothes", "legs", "accessories" }
local CHOICES = {}
for _, name in ipairs(probe:getSkins()) do
  local folder = name:match("^(.-)/")
  if folder then CHOICES[folder] = CHOICES[folder] or {}; table.insert(CHOICES[folder], name) end
end
fx.dispose(probe); probe = nil

local skinOf = setmetatable({}, { __mode = "k" })
local function build(obj, parts)
  local skin = MODE == "inplace" and skinOf[obj]
  if skin then skin:clear() else skin = obj:createSkin("avatar"); if MODE == "inplace" then skinOf[obj] = skin end end
  skin:addSkin("skin-base")
  for _, cat in ipairs(ORDER) do
    local name = parts[cat]
    if name and obj:findSkin(name) then skin:addSkin(name) end
  end
  obj:setSkin(skin)
end
math.randomseed(99)
local function pick(cat) local t = CHOICES[cat]; return t[math.random(#t)] end
local avatars, parts = {}, {}
for i = 1, N do
  avatars[i] = fx.create(data); parts[i] = {}
  for _, cat in ipairs(ORDER) do parts[i][cat] = pick(cat) end
  build(avatars[i], parts[i]); avatars[i]:setAnimation(1, "walk", true)
end
local ref = fx.create(data)
local function frame() for i = 1, N do avatars[i]:updateState(DT); fx.renderStats(avatars[i]) end end
for _ = 1, 20 do frame() end
fullgc()
local mem0 = fx.usedMemory()
local samples, checks, bad = {}, 0, 0
local t0 = os.clock()
for r = 1, REBUILDS do
  local i = math.random(N); local cat = ORDER[math.random(#ORDER)]
  parts[i][cat] = (math.random() < 0.1) and (cat .. "/does-not-exist") or pick(cat)
  build(avatars[i], parts[i])
  if r % 25 == 0 then
    checks = checks + 1; build(ref, parts[i])
    local a, b = fx.slotAttachments(avatars[i]), fx.slotAttachments(ref)
    local ba, bb = fx.activeBones(avatars[i]), fx.activeBones(ref)
    local n = 0; for k, v in pairs(b) do if a[k] ~= v then n = n + 1 end end
    for k, v in pairs(bb) do if ba[k] ~= v then n = n + 1 end end
    if n > 0 then bad = bad + 1 end
  end
  if r % 10 == 0 then frame() end
  if r % math.max(1, math.floor(REBUILDS / 8)) == 0 then fullgc(); samples[#samples + 1] = fx.usedMemory() - mem0 end
end
local elapsed = os.clock() - t0
print(("mode=%s avatars=%d rebuilds=%d: fresh-build comparisons %d (attachments + skin bones), mismatching %d")
  :format(MODE, N, REBUILDS, checks, bad))
local lo, hi = math.min(unpack(samples)), math.max(unpack(samples))
print("  spine heap after full GC vs warm baseline (bytes): " .. table.concat(samples, " "))
print(("  loop time %.1f ms (Mac host, includes %d frames of %d avatars; ratio use only)"):format(elapsed * 1000, REBUILDS / 10, N))
for i = 1, N do fx.dispose(avatars[i]) end
fx.dispose(ref); avatars, ref, data = nil, nil, nil
fullgc()
local c, f = fx.dataStats()
print(("  teardown: data created %d freed %d, spine heap %d B"):format(c, f, fx.usedMemory()))
local band = MODE == "inplace" and { -math.huge, 300 * 1024 } or { -70 * 1024, 70 * 1024 }
assert(bad == 0, bad .. " rebuilt avatars differ from a fresh build")
assert(lo >= band[1] and hi <= band[2], ("spine heap %+d..%+d B is outside the %s band"):format(lo, hi, MODE))
assert(c == f and fx.usedMemory() == 0, "teardown left spine memory behind")
