-- One run sample of the narrative docs pages, staged by suite.sh as docs-samples/<family>/<n>.lua (the arg),
-- in the real Simulator under the Simulator-side prelude, the globals the pages take as given: require of the line's
-- plugin name loads the real plugin, spine (that plugin), spineboy (spine.create of the line's spineboy, loaded from
-- assets/characters/ as the pages load it) and skeleton (the spineboy object). The sample then runs 2 s of real
-- frames, so its enterFrame listeners, timers and transitions run. A raise while loading or running the sample is an
-- ERROR, one in a listener an UNHANDLED_ERROR; either fails the scenario.
local L = require("simlib")
L.open("s23_docs_sample " .. L.arg)

spine = L.loadPlugin()
spineboy = spine.create(spine.loadSkeletonData("assets/characters/spineboy.json",
  spine.loadAtlas("assets/characters/spineboy.atlas")))
skeleton = spineboy

-- a nil path would make loadfile read stdin
local path = system.pathForFile(L.arg, system.ResourceDirectory)
local chunk, err = nil, "no sample " .. L.arg
if path then chunk, err = loadfile(path) end
local ok = chunk ~= nil
if ok then ok, err = pcall(chunk) end
if not ok then
  L.log("ERROR", err)
  L.finish(1)
end
timer.performWithDelay(2000, function() L.finish(0) end)
