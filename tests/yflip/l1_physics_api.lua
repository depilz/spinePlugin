-- gap-4: does the plugin's Lua physics:translate/rotate (shared/Lua_Physics.cpp:3-48) keep the same on-screen
-- direction in A (the plugin's configuration; 1.5.0: scaleY=-1) and B (Bone::setYDown(true))? Same Lua calls in A and B;
-- R (y-up) gets the mirrored call so that mirror(R) is the expected y-down result.
-- Frame loop = what Corona/Spine.lua does: updateState(ms) then draw() (updateState steps physics with UWT(Physics_Update); draw poses with Physics_Pose; meshes stubbed).
-- A case passes when A and B both match mirror(R).
local fx = require("realdata_fixture")
local function check(ok, id) print((ok and "PASS" or "FAIL") .. "\t" .. id) end  -- one check row per case
local function sim(mode, data, action)
  fx.setMode(mode)
  local s = fx.create(data)
  s:setEmptyAnimation(1, 0)          -- (1-based track index) a track is needed or updateState never advances physics (render-5)
  fx.worldTransformPhysics(s)
  local names = fx.boneNames(s)
  local traj = {}
  for f = 1, 90 do
    if f == 10 then action(s, mode) end
    s:updateState(1000 / 60)
    fx.worldTransformPhysics(s)
    local fr = {}
    for i, n in ipairs(names) do local x, y, r = fx.boneWorldFull(s, n); fr[i] = { x, y, r } end
    traj[f] = fr
  end
  fx.dispose(s)
  fx.setMode("A")
  return traj, names
end
local function adiff(a, b) local d = (a - b) % 360; if d > 180 then d = 360 - d end; return d end
local function cmp(t1, t2, mirror2)
  local mp, mr, where = 0, 0, ""
  for f = 1, #t1 do
    for i = 1, #t1[f] do
      local a, b = t1[f][i], t2[f][i]
      local by, br = b[2], b[3]
      if mirror2 then by, br = -by, -br end
      local p = math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - by) ^ 2)
      if p > mp then mp = p; where = ("bone#%d@f%d"):format(i, f) end
      local r = adiff(a[3], br); if r > mr then mr = r end
    end
  end
  return mp, mr, where
end
local skels = { "sack", "celestial-circus", "snowglobe", "cloud-pot" }
local probeBone = { sack = "belly", ["celestial-circus"] = "bench-back", snowglobe = "arm-l-elbow", ["cloud-pot"] = "cloud" }
for _, name in ipairs(skels) do
  local data = fx.loadData(name .. "/" .. name .. ".atlas", name .. "/" .. name .. ".skel")
  local actions = {
    ["physics:translate(0,60)"] = function(s, mode) s.physics:translate(0, mode == "R" and -60 or 60) end,
    ["physics:translate(60,0)"] = function(s, mode) s.physics:translate(60, 0) end,
    ["physics:rotate(root,30)"] = function(s, mode)
      local rx, ry = fx.boneWorld(s, "root"); s.physics:rotate(rx, ry, mode == "R" and -30 or 30) end,
  }
  for _, an in ipairs({ "physics:translate(0,60)", "physics:translate(60,0)", "physics:rotate(root,30)" }) do
    local tA, names = sim("A", data, actions[an])
    local tB = sim("B", data, actions[an])
    local tR = sim("R", data, actions[an])
    local ab_p, ab_r = cmp(tA, tB, false)
    local ar_p, ar_r = cmp(tA, tR, true)
    local br_p, br_r = cmp(tB, tR, true)
    -- on-screen direction of the probe bone right after the action (frame 11 vs frame 9), y down
    local idx; for i, n in ipairs(names) do if n == probeBone[name] then idx = i end end
    local function sdy(t, flip) local d = t[11][idx][2] - t[9][idx][2]; return flip and -d or d end
    local function sdx(t) return t[11][idx][1] - t[9][idx][1] end
    print(("%-16s %-24s A-vs-B max pos %9.4f rot %8.4f | A-vs-mirror(R) %9.4f / %8.4f | B-vs-mirror(R) %9.4f / %8.4f | %s screen d(x,y) f9->f11: A (%+.2f,%+.2f) B (%+.2f,%+.2f) R (%+.2f,%+.2f)")
      :format(name, an, ab_p, ab_r, ar_p, ar_r, br_p, br_r, probeBone[name], sdx(tA), sdy(tA), sdx(tB), sdy(tB), sdx(tR), sdy(tR, true)))
    check(math.max(ar_p, ar_r, br_p, br_r) < 1e-3, "l1_physics_api " .. name .. " " .. an)
  end
end
