-- S17: render digests of the sample exports (every example's first animation, skins, injections, split), logged
-- every 5th frame as "DIGEST <case> <label> <geometry> <layout>". Argument base loads plugin.spine (the shipped 1.5.0
-- dylib); spine42 loads the line's plugin (plugin.spine42: the scenario runs on the 4.2 line only) and checks each
-- case's geometry against the base run's results file, or against s17_moved.lua for a case an accepted runtime change
-- moved. The layout (how the vertices are split into mesh children) is logged and never compared.
-- Geometry comparison: nv, su, sv and every non-sum token (e.g. the injection event history) must match exactly. The
-- position sums sx, sy, sw may differ by float32 rounding, because the per-mesh vertex offset depends on how the
-- vertices are batched into meshes: |d| <= nv * 2^-23 * m (sw: times 3 * 96, its largest vertex weight), where m is the
-- largest |x| or |y| of the spine42 digest, plus 1e-4 for the %.4f print rounding. Those whole-group bounds grow with
-- nv, so the tuple also carries blocked sums: bx by per BLOCK consecutive vertices of the group's running vertex index
-- (like sw, independent of the batching), each within BLOCK * 2^-23 * m + 1e-4. Moving one vertex by 0.01 fails every
-- case that draws geometry, as does a dropped clipping or masks patch.
local L = require("simlib")
L.watchdogMs = 240000
L.open("s17_digest " .. L.arg)
local spine = L.loadPlugin(L.arg == "base" and "plugin.spine" or nil)
local gidx = getmetatable(display.newGroup()).__index
local EXAMPLES = { "alien","celestial-circus","chibi-stickers","cloud-pot","coin","goblins","mix-and-match",
  "owl","powerup","raptor","sack","snowglobe","speedy","spineboy","stretchyman","tank","vine","windmill" }
local FRAMES = 40
local BLOCK = 16 -- vertices per blocked sum

-- digest(group) -> geometry "nv sx sy sw su sv bx1 by1 bx2 by2 ...", layout "n sa nb", largest |x| or |y|. getVertex
-- returns the positions the plugin wrote, not re-centred on mesh.x/y, so the geometry sums depend on the grouping only
-- through float32 rounding of the positions (see the header); sw and the block sums follow each vertex's running index
-- over the whole group, so they hold while the draw order does.
local function digest(group)
  local n = gidx(group, "numChildren")
  local nv, sx, sy, sw, su, sv, sa, nb, m = 0, 0, 0, 0, 0, 0, 0, 0, 0
  local bx, by = {}, {}
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
        local b = math.floor((nv - 1) / BLOCK) + 1
        bx[b], by[b] = (bx[b] or 0) + x, (by[b] or 0) + y
        m = math.max(m, math.abs(x), math.abs(y))
        if ok2 and u then su = su + u; sv = sv + v end
        k = k + 1
      end
    end
  end
  local geometry = { ("%d %.4f %.4f %.4f %.5f %.5f"):format(nv, sx, sy, sw, su, sv) }
  for b = 1, #bx do geometry[b + 1] = ("%.4f %.4f"):format(bx[b], by[b]) end
  return table.concat(geometry, " "), ("%d %.4f %d"):format(n, sa, nb), m
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

-- play(obj, frames, emit, label, extra): updateState(16) + draw() per frame, a digest every 5th frame; extra() returns
-- more geometry and, optionally, more layout and its largest coordinate
local function play(obj, frames, emit, label, extra)
  for fr = 1, frames do
    obj:updateState(16); obj:draw()
    if fr % 5 == 0 then
      local geometry, layout, m = digest(obj)
      if extra then
        local g, l, em = extra()
        geometry, layout, m = geometry .. " " .. g, layout .. (l and " " .. l or ""), math.max(m, em or 0)
      end
      emit(("%s%d"):format(label or "", fr), geometry, layout, m)
    end
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
  local function splitDigest()
    local g, l, m = digest(group)
    return "| " .. g, "| " .. l, m
  end
  play(obj, 20, emit, "split ", splitDigest)
  obj:reassemble(); play(obj, 10, emit, "reassembled ")
  group = obj:split(odd); play(obj, 10, emit, "resplit ", splitDigest)
end, "raptor" }

local mine, largest = {}, {}
for _, case in ipairs(CASES) do
  local label, run, name = case[1], case[2], case[3]
  mine[label], largest[label] = {}, {}
  local function emit(at, geometry, layout, m)
    mine[label][#mine[label] + 1] = at .. "\t" .. geometry
    largest[label][#mine[label]] = m or 0
    L.log("DIGEST", label, at, geometry, layout or "")
  end
  local ok, err = pcall(function()
    local obj = newObject(name)
    run(obj, emit)
    obj:removeSelf()
  end)
  if not ok then emit("error", tostring(err)) end
end

-- base geometry: case -> list of "label\tgeometry", from the results file of the "base" run
local function readBase()
  local f = io.open(L.dir .. "/s17_digest_base.txt")
  if not f then return nil end
  local base = {}
  for line in f:lines() do
    local label, at, geometry = line:match("^DIGEST\t([^\t]*)\t([^\t]*)\t([^\t]*)")
    if label then base[label] = base[label] or {}; table.insert(base[label], at .. "\t" .. geometry) end
  end
  f:close()
  return base
end

local EPS = 2 ^ -23
local SUM_WEIGHT = { [2] = 1, [3] = 1, [4] = 3 * 96 } -- position of sx, sy, sw in a "nv sx sy sw su sv" tuple

-- sumBound(at, nv, m): the float32 rounding bound of the tuple's token at position at, nil for a token compared exactly;
-- the block sums follow sv, two tokens per BLOCK vertices
local function sumBound(at, nv, m)
  if SUM_WEIGHT[at] then return nv * EPS * m * SUM_WEIGHT[at] + 1e-4 end
  if at > 6 and at <= 6 + 2 * math.ceil(nv / BLOCK) then return BLOCK * EPS * m + 1e-4 end
end

local function words(s)
  local t = {}
  for w in s:gmatch("%S+") do t[#t + 1] = w end
  return t
end

-- sameGeometry(a, b, m): the "label\tgeometry" entries a and b are equal but for float32 rounding of the position sums;
-- a geometry tuple starts at the first geometry token and after each "|"
local function sameGeometry(a, b, m)
  local la, ga = a:match("^([^\t]*)\t(.*)$")
  local lb, gb = b:match("^([^\t]*)\t(.*)$")
  if not (ga and gb) or la ~= lb then return a == b end
  local wa, wb = words(ga), words(gb)
  if #wa ~= #wb then return false end
  local at, nv = 0, 0 -- at: the token's position in its tuple
  for i = 1, #wa do
    at = wa[i] == "|" and 0 or at + 1
    if at == 1 then nv = tonumber(wa[i]) or 0 end
    local bound, x, y = sumBound(at, nv, m), tonumber(wa[i]), tonumber(wb[i])
    if bound and x and y then
      if math.abs(x - y) > bound then return false end
    elseif wa[i] ~= wb[i] then return false end
  end
  return true
end

local function firstDifference(a, b, source, m)
  for i = 1, math.max(#a, #b) do
    if not (a[i] and b[i] and sameGeometry(a[i], b[i], m[i] or 0)) then
      return ("#%d %s %s spine42 %s"):format(i, source, tostring(a[i]), tostring(b[i]))
    end
  end
end

if L.arg ~= "base" then
  local base, moved = readBase(), require("s17_moved")
  L.check("baseline", base ~= nil, "results of s17_digest base")
  for _, case in ipairs(CASES) do
    local label = case[1]
    local diff, cause = "no base digests", moved[label] and moved[label].cause
    if moved[label] and (type(cause) ~= "string" or cause == "") then diff = "s17_moved entry without a cause"
    elseif moved[label] then diff = firstDifference(moved[label], mine[label], "s17_moved", largest[label])
    elseif base and base[label] then diff = firstDifference(base[label], mine[label], "base", largest[label]) end
    L.check(label, diff == nil, diff or (#mine[label] .. " digests equal"))
  end
end
timer.performWithDelay(300, function() L.finish(0) end)
