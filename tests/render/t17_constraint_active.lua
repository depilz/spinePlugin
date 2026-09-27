-- Constraint activation through the real getters. t17_constraint_active.lua [ik|physics|ik-timeline]
-- A skin-required constraint reads isActive == false while the current skin lacks it and true once the skin has it;
-- the timeline of a skin-inactive IK constraint leaves its pose alone.
local C = dofile(arg[0]:match("^(.*)/") .. "/common.lua")
local fx = C.fx
local part = arg[1]
local function ik(obj, name)
  for _, c in ipairs(obj.ikConstraints) do if c.name == name then return c end end
end

if part == "ik" or part == "physics" then
  local obj = C.spine.create(C.data(part == "ik" and "spineboy" or "sack", 0.5))
  local name = part == "ik" and "aim-ik" or fx.physicsInfo(obj)[1].name
  local constraint = part == "ik" and ik(obj, name) or obj.physics
  C.expect(constraint.isActive == true, part .. " " .. name .. " is active before it is skin-required")
  fx.skinRequire(obj, part, name)
  obj:setSkin("default")
  print(part, name, "skin lacks it: isActive =", constraint.isActive)
  C.expect(constraint.isActive == false, part .. " " .. name .. " is inactive while the current skin lacks it")
  fx.skinRequire(obj, part, name, "default")
  obj:setSkin("default")
  print(part, name, "skin has it: isActive =", constraint.isActive)
  C.expect(constraint.isActive == true, part .. " " .. name .. " is active once the current skin has it")
  obj:removeSelf()
end

-- spineboy "aim" keys aim-ik mix 0.995 (setup 0)
if part == "ik-timeline" then
  local function aimMix(skinName)
    local obj = C.spine.create(C.data("spineboy", 0.5))
    fx.skinRequire(obj, "ik", "aim-ik", skinName)
    obj:setSkin("default")
    obj:setAnimation(1, "aim", true)
    C.frame(obj, 1000 / 60)
    local c = ik(obj, "aim-ik")
    local active, mix = c.isActive, c.mix
    obj:removeSelf()
    return active, mix
  end
  local inactive, inactiveMix = aimMix(nil)
  local active, activeMix = aimMix("default")
  print(("aim-ik after one frame of aim: skin lacks it: isActive=%s mix=%.3f; skin has it: isActive=%s mix=%.3f")
    :format(tostring(inactive), inactiveMix, tostring(active), activeMix))
  C.expect(not inactive and inactiveMix == 0, "the aim timeline leaves a skin-inactive aim-ik at its setup mix 0")
  C.expect(active and activeMix > 0.9, "the aim timeline keys an active aim-ik to mix 0.995")
end
C.done()
