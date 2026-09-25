-- Harness shim: the headless spine object has no Solar2D display group, so skeleton_index's fallback to the
-- group __index is a null holder (unknown keys would crash the host). Emulate Solar2D (unknown key -> nil).
return function(o)
  local mt = getmetatable(o)
  if rawget(mt, "__skinsapi_shim") then return end
  local orig = mt.__index
  local special = { isActive = 1, timeScale = 1, slots = 1, bones = 1, ikConstraints = 1, physics = 1, tracks = 1, fill = 1, numChildren = 1 }
  mt.__index = function(t, k)
    if special[k] or rawget(mt, k) ~= nil then return orig(t, k) end
    return nil
  end
  rawset(mt, "__skinsapi_shim", true)
end
