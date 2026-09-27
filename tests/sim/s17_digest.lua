-- S17: render digests of the sample exports (every example's first animation, skins, injections, split), logged
-- every 5th frame as "DIGEST <case> <label> <digest>". Argument base loads plugin.spine (the shipped 1.5.0 dylib);
-- spine42 loads plugin.spine42 and checks each case's digests against the base run's results file.
local L = require("simlib")
L.watchdogMs = 240000
L.open("s17_digest " .. L.arg)
local spine = L.loadPlugin(L.arg == "base" and "plugin.spine" or "plugin.spine42")
local gidx = getmetatable(display.newGroup()).__index
local EXAMPLES = { "alien","celestial-circus","chibi-stickers","cloud-pot","coin","dragon","goblins","hero","mix-and-match",
  "owl","powerup","raptor","sack","snowglobe","speedy","spineboy","stretchyman","tank","vine","windmill" }
local FRAMES = 40

local function digest(group)
  local n = gidx(group, "numChildren")
  local nv, sx, sy, sw, su, sv, sa, nb = 0, 0, 0, 0, 0, 0, 0, 0
  for i = 1, n do
    local c = gidx(group, i)
    sa = sa + (c.alpha or 0) * i
    if c.blendMode and c.blendMode ~= "normal" then nb = nb + i end
    local p = c.path
    if p and p.type == "mesh" then
      local k = 1
      while true do
        local ok, x, y = pcall(p.getVertex, p, k)
        if not ok or x == nil then break end
        local ok2, u, v = pcall(p.getUV, p, k)
        nv = nv + 1; sx = sx + x; sy = sy + y; sw = sw + (nv % 97) * (x + 2 * y)
        if ok2 and u then su = su + u; sv = sv + v end
        k = k + 1
      end
    end
  end
  return ("%d %d %.4f %.4f %.4f %.5f %.5f %.4f %d"):format(n, nv, sx, sy, sw, su, sv, sa, nb)
end

local datas = {}
local function skeletonData(name)
  if not datas[name] then
    local atlas = spine.loadAtlas(("spines/%s/%s.atlas"):format(name, name))
    datas[name] = spine.loadSkeletonData(("spines/%s/%s.skel"):format(name, name), atlas, 0.25)
  end
  return datas[name]
end

local function newObject(name)
  local obj = spine.create(skeletonData(name))
  obj.x, obj.y = 384, 800
  local anims = obj:getAnimations()
  table.sort(anims)
  obj:setAnimation(1, anims[1], true)
  return obj
end

-- play(obj, frames, emit, label, extra): updateState(16) + draw() per frame, a digest every 5th frame
local function play(obj, frames, emit, label, extra)
  for fr = 1, frames do
    obj:updateState(16); obj:draw()
    if fr % 5 == 0 then emit(("%s%d"):format(label or "", fr), digest(obj) .. (extra and " " .. extra() or "")) end
  end
end

local function nonDefaultSkins(obj)
  local skins = {}
  for _, s in ipairs(obj:getSkins()) do if s ~= "default" then skins[#skins + 1] = s end end
  table.sort(skins)
  return skins
end

local CASES = {}
for _, name in ipairs(EXAMPLES) do
  CASES[#CASES + 1] = { name, function(obj, emit) play(obj, FRAMES, emit) end, name }
end
CASES[#CASES + 1] = { "skins goblins", function(obj, emit)
  for _, skin in ipairs(nonDefaultSkins(obj)) do obj:setSkin(skin); play(obj, 10, emit, skin .. " ") end
  obj:setSkin("goblin", false); play(obj, 10, emit, "keep-slots ")
end, "goblins" }
CASES[#CASES + 1] = { "skins mix-and-match", function(obj, emit)
  local combo = obj:createSkin("combo")
  for i, skin in ipairs(nonDefaultSkins(obj)) do
    if i % 3 == 1 then combo:addSkin(skin) end
  end
  obj:setSkin(combo); play(obj, 20, emit, "combo ")
  obj:setSkin("full-skins/girl"); play(obj, 10, emit, "girl ")
end, "mix-and-match" }
CASES[#CASES + 1] = { "injections raptor", function(obj, emit)
  local head, gun = display.newRect(0, 0, 30, 20), display.newCircle(0, 0, 8)
  local seen = {}
  obj:inject(head, "head", function(e)
    seen[#seen + 1] = ("%.4f,%.4f,%.4f,%.4f,%.4f"):format(e.x, e.y, e.rotation, e.xScale, e.yScale)
  end)
  obj:inject(gun, "gun")
  local function events() local s = #seen .. ":" .. table.concat(seen, ";"); seen = {}; return s end
  play(obj, 20, emit, "inject ", events)
  obj:changeInjectionSlot(gun, "stirrup-front"); play(obj, 10, emit, "moved ", events)
  obj:eject(head); play(obj, 10, emit, "ejected ", events)
  head:removeSelf()
end, "raptor" }
CASES[#CASES + 1] = { "split raptor", function(obj, emit)
  local even, odd = {}, {}
  for i, slot in ipairs(obj.slots) do table.insert(i % 2 == 0 and even or odd, slot.name) end
  local group = obj:split(even)
  local function splitDigest() return "| " .. digest(group) end
  play(obj, 20, emit, "split ", splitDigest)
  obj:reassemble(); play(obj, 10, emit, "reassembled ")
  group = obj:split(odd); play(obj, 10, emit, "resplit ", splitDigest)
end, "raptor" }

local mine = {}
for _, case in ipairs(CASES) do
  local label, run, name = case[1], case[2], case[3]
  mine[label] = {}
  local function emit(at, d)
    mine[label][#mine[label] + 1] = at .. "\t" .. d
    L.log("DIGEST", label, at, d)
  end
  local ok, err = pcall(function()
    local obj = newObject(name)
    run(obj, emit)
    obj:removeSelf()
  end)
  if not ok then emit("error", tostring(err)) end
end

-- base digests: case -> list of "label\tdigest", from the results file of the "base" run
local function readBase()
  local f = io.open(L.dir .. "/s17_digest_base.txt")
  if not f then return nil end
  local base = {}
  for line in f:lines() do
    local label, rest = line:match("^DIGEST\t([^\t]*)\t(.*)$")
    if label then base[label] = base[label] or {}; table.insert(base[label], rest) end
  end
  f:close()
  return base
end

local function firstDifference(a, b)
  for i = 1, math.max(#a, #b) do
    if a[i] ~= b[i] then return ("#%d base %s spine42 %s"):format(i, tostring(a[i]), tostring(b[i])) end
  end
end

if L.arg ~= "base" then
  local base = readBase()
  L.check("baseline", base ~= nil, "results of s17_digest base")
  for _, case in ipairs(CASES) do
    local label = case[1]
    local diff = "no base digests"
    if base and base[label] then diff = firstDifference(base[label], mine[label]) end
    L.check(label, diff == nil, diff or (#mine[label] .. " digests equal"))
  end
end
timer.performWithDelay(300, function() L.finish(0) end)
