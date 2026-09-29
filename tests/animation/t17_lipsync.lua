-- T17: headless replay of the app's lip sync queue against the 1.5.0 recording.
-- speak() replays LipSyncer:speak from its cancel() on (APP games/shared/components/LipSyncer.lua at b1219fec64,
-- default config) over already compacted visemes; blink() replays DialogueCat's playBlink. The rig is a stand-in:
-- tests/animation/assets/<line>/lipsync.json, 200 ms lips_*/eyes_blink and a 1 s eyes_camera.
-- t17_lipsync.lua normal|early|edge: prints every began/ended as "<update> <track> <phase> <animation>" (60 Hz
-- updates) and checks it against the recording: each entry within one update of it, in the same order.
local spine = require("plugin.spine")
local W = arg[0]:match("^(.*)/")
local C = dofile(W .. "/../check.lua")
local mode = arg[1]
local data = spine.loadSkeletonData(W .. "/assets/" .. os.getenv("SPINE_RUNTIME") .. "/lipsync.json",
  spine.loadAtlas("spineboy/spineboy.atlas"))

local LIP, EYE, BLINK = 2, 3, 4
local OFFSET, MIN_BLENDING = 100, 70

-- compacted visemes { viseme, startTime, endTime } in ms from the start of the audio
local speech = {
  -- first viseme after the offset: the queue starts from LipSyncer's own empty entry; the repeated "o" is skipped
  normal = { { "a", 150, 230 }, { "o", 230, 300 }, { "ee", 300, 420 }, { "a", 420, 480 }, { "m", 480, 600 },
    { "o", 600, 700 }, { "o", 700, 780 } },
  -- first viseme inside the offset, second after it: setAnimation, then increasing times
  early = { { "m", 40, 160 }, { "a", 160, 250 }, { "o", 250, 330 }, { "ee", 330, 450 } },
  -- first two visemes inside the offset: both shift to 0, so the second is queued at the first one's start (L14)
  edge = { { "a", 30, 90 }, { "o", 90, 200 }, { "ee", 200, 290 }, { "m", 290, 400 }, { "a", 400, 520 } },
}

-- The recording per line. 4.2 normal and early are the 1.5.0 recording (this script on the 6d33a72 4.2 build, whose
-- AnimationState.cpp is 1.5.0's). 4.3 normal and early are the 6d33a72 4.3 build's: the same began updates, but the
-- 4.3 mixing model ends a mixed-out lips entry with the rest of its mixing chain. edge is the L14 recording: the
-- queued visemes start at their own times instead of after the first viseme completes (1.5.0: o 14, ee 26, m 38, a 50).
local recorded = {
  ["4.2"] = {
    normal = {
      "0 4 began eyes_blink", "0 3 began eyes_camera", "0 2 began <empty>", "5 2 began lips_a", "9 2 began lips_o",
      "9 4 began <empty>", "10 2 ended <empty>", "14 2 began lips_ee", "14 4 ended eyes_blink", "15 4 ended <empty>",
      "21 2 began lips_a", "22 2 ended lips_o", "24 2 began lips_m", "28 2 ended lips_ee", "30 4 began eyes_blink",
      "31 2 ended lips_a", "31 2 ended lips_a", "32 2 began lips_o", "38 4 began <empty>", "39 2 ended lips_m",
      "43 4 ended eyes_blink", "44 4 ended <empty>", "47 3 began <empty>", "52 3 ended eyes_camera",
      "53 3 ended <empty>"
    },
    early = {
      "0 4 began eyes_blink", "0 3 began eyes_camera", "0 2 began lips_m", "5 2 began lips_a", "9 4 began <empty>",
      "11 2 began lips_o", "14 4 ended eyes_blink", "15 2 began lips_ee", "15 4 ended <empty>", "18 2 ended lips_a",
      "22 2 ended lips_o", "22 2 ended lips_m", "27 3 began <empty>", "30 4 began eyes_blink",
      "32 3 ended eyes_camera", "33 3 ended <empty>", "38 4 began <empty>", "43 4 ended eyes_blink",
      "44 4 ended <empty>"
    },
    edge = {
      "0 4 began eyes_blink", "0 3 began eyes_camera", "0 2 began lips_a", "2 2 began lips_o", "8 2 began lips_ee",
      "9 4 began <empty>", "13 2 began lips_m", "14 4 ended eyes_blink", "15 2 ended lips_o", "15 4 ended <empty>",
      "20 2 began lips_a", "21 2 ended lips_ee", "27 2 ended lips_m", "27 2 ended lips_a", "30 4 began eyes_blink",
      "31 3 began <empty>", "36 3 ended eyes_camera", "37 3 ended <empty>", "38 4 began <empty>",
      "43 4 ended eyes_blink", "44 4 ended <empty>"
    },
  },
  ["4.3"] = {
    normal = {
      "0 4 began eyes_blink", "0 3 began eyes_camera", "0 2 began <empty>", "5 2 began lips_a", "9 2 began lips_o",
      "9 4 began <empty>", "10 2 ended <empty>", "14 2 began lips_ee", "14 4 ended eyes_blink", "15 4 ended <empty>",
      "21 2 began lips_a", "24 2 began lips_m", "30 4 began eyes_blink", "31 2 ended lips_a", "31 2 ended lips_ee",
      "31 2 ended lips_o", "31 2 ended lips_a", "32 2 began lips_o", "38 4 began <empty>", "39 2 ended lips_m",
      "43 4 ended eyes_blink", "44 4 ended <empty>", "47 3 began <empty>", "52 3 ended eyes_camera",
      "53 3 ended <empty>"
    },
    early = {
      "0 4 began eyes_blink", "0 3 began eyes_camera", "0 2 began lips_m", "5 2 began lips_a", "9 4 began <empty>",
      "11 2 began lips_o", "14 4 ended eyes_blink", "15 2 began lips_ee", "15 4 ended <empty>", "22 2 ended lips_o",
      "22 2 ended lips_a", "22 2 ended lips_m", "27 3 began <empty>", "30 4 began eyes_blink",
      "32 3 ended eyes_camera", "33 3 ended <empty>", "38 4 began <empty>", "43 4 ended eyes_blink",
      "44 4 ended <empty>"
    },
    edge = {
      "0 4 began eyes_blink", "0 3 began eyes_camera", "0 2 began lips_a", "2 2 began lips_o", "8 2 began lips_ee",
      "9 4 began <empty>", "13 2 began lips_m", "14 4 ended eyes_blink", "15 4 ended <empty>", "20 2 began lips_a",
      "27 2 ended lips_m", "27 2 ended lips_ee", "27 2 ended lips_o", "27 2 ended lips_a", "30 4 began eyes_blink",
      "31 3 began <empty>", "36 3 ended eyes_camera", "37 3 ended <empty>", "38 4 began <empty>",
      "43 4 ended eyes_blink", "44 4 ended <empty>"
    },
  },
}

local function shifted(t) return t <= OFFSET and 0 or t - OFFSET end
local function clamp(v, lo, hi) return math.min(math.max(v, lo), hi) end
local function blend(entry, ms) if type(entry) == "userdata" then entry.mixDuration = ms end end

local function speak(skeleton, visemes)
  skeleton:clearTrack(LIP)
  skeleton:clearTrack(EYE)
  skeleton:setAnimation(EYE, "eyes_camera", false)
  local first = visemes[1]
  local entry
  if shifted(first[2]) > 0 then
    skeleton:setEmptyAnimation(LIP, 0)
    entry = skeleton:addAnimationAt(LIP, "lips_" .. first[1], false, shifted(first[2]))
  else
    entry = skeleton:setAnimation(LIP, "lips_" .. first[1], false)
  end
  blend(entry, clamp((visemes[2] and visemes[2][2] - first[2] or 200) * 0.5, MIN_BLENDING, 200))
  local prev = first[1]
  for i = 2, #visemes do
    local v = visemes[i]
    if v[1] ~= prev then
      prev = v[1]
      blend(skeleton:addAnimationAt(LIP, "lips_" .. v[1], false, shifted(v[2])), clamp(OFFSET, MIN_BLENDING, math.huge))
    end
  end
  skeleton:addEmptyAnimation(EYE, MIN_BLENDING, shifted(visemes[#visemes][3] + MIN_BLENDING))
end

local function blink(skeleton)
  skeleton:setAnimation(BLINK, "eyes_blink", false)
  skeleton:addEmptyAnimation(BLINK, 80, 200 - 80)
end

local update, log = 0, {}
local s = spine.create(data, function(ev)
  if ev.phase == "began" or ev.phase == "ended" then
    log[#log + 1] = ("%d %d %s %s"):format(update, ev.trackIndex, ev.phase, ev.animation)
  end
end)
blink(s)
speak(s, speech[mode])
for i = 1, 90 do
  update = i
  if i == 30 then blink(s) end
  s:updateState(1000 / 60)
end
for _, line in ipairs(log) do print(line) end

local want = recorded[os.getenv("SPINE_RUNTIME")][mode]
C.expect(#log == #want, ("%s: %d events, recorded %d"):format(mode, #log, #want))
for i = 1, math.max(#log, #want) do
  local got, rec = log[i] or "", want[i] or ""
  local gu, gk = got:match("^(%d+) (.*)$")
  local ru, rk = rec:match("^(%d+) (.*)$")
  C.expect(gk ~= nil and gk == rk and math.abs(tonumber(gu) - tonumber(ru)) <= 1,
    ("%s event %d: %q, recorded %q"):format(mode, i, got, rec))
end
C.done()
