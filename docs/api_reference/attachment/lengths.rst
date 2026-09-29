=======================================
attachment.lengths
=======================================

| **Type:** ``table`` (read-only)
| **Attachment Types:** path

An array of curve segment lengths for the path attachment.

Each value represents the length (in the setup pose) from the start of the path
to the end of each curve segment. This data is used for constant speed path
following and path positioning calculations.

Example
-------

.. code-block:: lua

   local pathSlot = skeleton:findSlot("weapon-morningstar-path")
   local path = pathSlot.attachment

   if path and path.type == "path" then
       local lengths = path.lengths

       print("Path has", #lengths, "curve segments")

       -- Print each segment length
       for i, length in ipairs(lengths) do
           print("Segment", i, "length:", length)
       end

       -- Total path length is the last value
       if #lengths > 0 then
           local totalLength = lengths[#lengths]
           print("Total path length:", totalLength)
       end
   end

**Using with constant speed:**

.. code-block:: lua

   local trackPath = skeleton:findSlot("weapon-morningstar-path").attachment

   if trackPath and trackPath.type == "path" then
       if trackPath.constantSpeed then
           -- Lengths are used to normalize speed
           print("Normalized path with total length:",
                 trackPath.lengths[#trackPath.lengths])
       end
   end

Notes
-----

- Read-only - cannot be modified at runtime
- Values are cumulative from the start of the path
- Last value is the total path length
- Used internally for path constraint calculations
- Only relevant when ``constantSpeed`` is enabled
- Measured in Spine units from the setup pose

See Also
--------

- :doc:`constantSpeed` - Whether to use these lengths for speed normalization
- :doc:`closed` - Whether the path is a closed loop
- :doc:`vertices` - The path's vertex data

