-- gap-4: are the Lua-visible values identical between A (the plugin's configuration; 1.5.0: scaleY=-1) and B (Bone::setYDown(true))?
-- Reads slot.bone.{worldX,worldY,worldRotation,worldScaleX,worldScaleY,a,b,c,d,x,y,rotation} for every slot and
-- skeleton:getBounds()/getSize(), every frame, through the real bindings. Gravity-free skeletons only (gravity differs by design).
-- A case passes when every value is identical.
local fx = require("realdata_fixture")
local function check(ok, id) print((ok and "PASS" or "FAIL") .. "\t" .. id) end  -- one check row per case
local keys = { "worldX", "worldY", "worldRotation", "worldScaleX", "worldScaleY", "a", "b", "c", "d", "x", "y", "rotation" }
local function sim(mode, data, anim)
  fx.setMode(mode)
  local s = fx.create(data)
  s:setAnimation(1, anim, true)
  local out = {}
  local slots = s:getSlotNames()
  for f = 1, 60 do
    s:updateState(1000 / 60)
    fx.worldTransformPhysics(s)
    local fr = {}
    for _, sn in ipairs(slots) do
      local b = s:getSlot(sn).bone
      for _, k in ipairs(keys) do fr[#fr + 1] = b[k] end
    end
    local bb = s:getBounds()
    fr[#fr + 1] = bb.xMin; fr[#fr + 1] = bb.yMin; fr[#fr + 1] = bb.xMax; fr[#fr + 1] = bb.yMax
    out[f] = fr
  end
  fx.dispose(s)
  fx.setMode("A")
  return out, #slots
end
for _, spec in ipairs({ { "spineboy", "run" }, { "spineboy", "aim" }, { "raptor", "walk" }, { "mix-and-match", "walk" },
                        { "sack", "walk" }, { "celestial-circus", "swing" }, { "snowglobe", "shake" }, { "stretchyman", "sneaky" }, { "tank", "drive" } }) do
  local name, anim = spec[1], spec[2]
  local data = fx.loadData(name .. "/" .. name .. ".atlas", name .. "/" .. name .. ".skel")
  local ok, a, nslots = pcall(sim, "A", data, anim)
  local same = false
  if not ok then print(name, anim, "error", a) else
    local b = sim("B", data, anim)
    local maxd, n = 0, 0
    for f = 1, #a do for i = 1, #a[f] do n = n + 1; local d = math.abs(a[f][i] - b[f][i]); if d > maxd then maxd = d end end end
    print(("%-16s %-8s slots=%3d values compared=%7d  max |A-B| = %g"):format(name, anim, nslots, n, maxd))
    same = maxd == 0
  end
  check(same, "l2_lua_visible " .. name .. " " .. anim)
end
