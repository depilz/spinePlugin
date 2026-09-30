-- Asset paths of the line's exports the skins tests read, relative to the cwd ($SPINE_SPINES).
local W = debug.getinfo(1, "S").source:sub(2):match("^(.*/)")
local fixture = W .. "../lifecycle/assets/4.2/sequence/sequence"
local assets = {
  goblins = { "goblins/goblins.atlas", "goblins/goblins.json" },
  mix = { "mix-and-match/mix-and-match.atlas", "mix-and-match/mix-and-match.json" },
  -- the line's sequence rig: the slot and attachment key its animation's sequence timeline drives. 4.2 has no Esoteric
  -- sequence rig: the generated fixture.
  sequence = ({
    ["4.2"] = { fixture .. ".atlas", fixture .. ".json", slot = "seq", key = "seq", anim = "flip" },
    ["4.3"] = { "diamond/diamond.atlas", "diamond/diamond.json", slot = "top-shine", key = "top", anim = "idle-still" },
  })[os.getenv("SPINE_RUNTIME")],
}
assert(assets.sequence, "no sequence rig for SPINE_RUNTIME " .. tostring(os.getenv("SPINE_RUNTIME")))
return assets
