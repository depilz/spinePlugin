===================================
trackEntry.animationLast
===================================

| **Type:** ``number``
| **See also:** :doc:`index`

Overview
--------

The time in milliseconds this animation was last applied. Some timelines use this for one-time triggers. Eg,
when this animation is applied, event timelines will fire all events between the animationLast time
(exclusive) and animationTime (inclusive). Defaults to ``-1`` to ensure triggers on frame 0 happen the first
time this animation is applied.

Example
-------

.. code-block:: lua

    local spine = require("@SPINE_PLUGIN@")
    local atlas = spine.loadAtlas("assets/characters/spineboy.atlas")
    local skeletonData = spine.loadSkeletonData("assets/characters/spineboy.skel", atlas)
    local spineboy = spine.create(skeletonData)

    -- Set the "shoot" animation on track 1
    spineboy:setAnimation(1, "shoot", false)
    spineboy.tracks[1].animationLast = 300  -- Use a custom animationLast time

    -- Update the animation state each frame and monitor animation end
    local function onEnterFrame(event)
        spineboy:updateState(event.time)
        spineboy:draw()
    end

    Runtime:addEventListener("enterFrame", onEnterFrame)
