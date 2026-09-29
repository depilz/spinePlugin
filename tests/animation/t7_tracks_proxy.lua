-- T7: s.tracks is a snapshot table built on each read (D18): tracks[i] = TrackEntry wrapper or false for an empty
-- track, up to the highest track; a held table outlives the skeleton (animation-3) and only its entries raise.
local spine = require("plugin.spine")
local C = dofile(arg[0]:match("^(.*)/") .. "/../check.lua")
local data = spine.loadSkeletonData("spineboy/spineboy.json", spine.loadAtlas("spineboy/spineboy.atlas"))

-- sparse: only track 3 set -> {false, false, entry}
local sp = spine.create(data)
local e3 = sp:setAnimation(3, "walk", true)
local st = sp.tracks
print("sparse:", type(st), #st, st[1], st[2], st[3] and st[3].animation)
C.expect(type(st) == "table" and getmetatable(st) == nil, "tracks is not a plain table")
C.expect(#st == 3 and st[1] == false and st[2] == false, "sparse tracks are not {false, false, entry}")
C.expect(st[3] and st[3].animation == "walk" and st[3].index == 3, "tracks[3] is not track 3's entry")
C.expect(__native.entryPtr(st[3]) == __native.entryPtr(e3), "tracks[3] wraps another entry")
local visited = {}
for i, tr in ipairs(st) do visited[#visited + 1] = i .. "=" .. (tr and tr.animation or tostring(tr)) end
print("ipairs:", table.concat(visited, " "))
C.expect(table.concat(visited, " ") == "1=false 2=false 3=walk", "ipairs does not visit every track")
C.expect(sp.tracks ~= st, "two reads return the same table")

-- a snapshot does not follow later changes; a fresh read does
sp:setAnimation(1, "run", true)
C.expect(st[1] == false and sp.tracks[1].animation == "run", "snapshot/fresh read after setAnimation(1)")
sp:clearTrack(3)
print("after clearTrack(3): #tracks", #sp.tracks, "tracks[3]", sp.tracks[3])
C.expect(#sp.tracks == 3 and sp.tracks[3] == false, "a cleared track does not read false")

-- a skeleton without tracks
local none = spine.create(data)
C.expect(#none.tracks == 0 and next(none.tracks) == nil, "tracks of a fresh skeleton is not empty")

-- held table after removeSelf() and the next-frame dispose: never reaches the freed AnimationState
local s = spine.create(data)
s:setAnimation(1, "walk", true)
local tracks = s.tracks
print("#tracks before dispose", #tracks)
s:removeSelf(); __stub.frame()
collectgarbage()
print("#tracks after dispose ->", #tracks, type(tracks[1]))
C.expect(#tracks == 1 and type(tracks[1]) == "userdata", "held tracks table changed after dispose")
local ok, err = pcall(function() return tracks[1].animation end)
print(ok, err)
C.expect(not ok and tostring(err):find("Track entry belongs to a removed skeleton", 1, true),
  "a held entry of a removed skeleton did not raise")
print("end of script")
C.done()
