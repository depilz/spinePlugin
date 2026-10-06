=======================================
attachment.region
=======================================

| **Type:** ``table`` or ``nil`` (read-only)
| **Attachment types:** region, mesh
| **See also:** :doc:`index`, :doc:`copy`, :doc:`path`, :doc:`../skeleton/createAttachment`

Overview
--------

The atlas region a region or mesh attachment shows in its setup frame, as a new table on each read. Attachments
without a region (bounding box, path, point and clipping) read ``nil``.

The table's fields:

- ``name`` – the region's name in the atlas.
- ``filename``, ``baseDir`` – the page texture's file, as the plugin loaded it (absent when that texture failed to
  load).
- ``x``, ``y`` – the region's position on its atlas page, in pixels.
- ``width``, ``height`` – the region's packed size as it lies on the page; for a region rotated 90° they are
  swapped relative to ``originalWidth`` and ``originalHeight``.
- ``originalWidth``, ``originalHeight`` – the image's size before whitespace was stripped.
- ``offsetX``, ``offsetY`` – where the stripped image sits inside the original size.
- ``rotated`` – ``true`` when the region is rotated 90° on the page; ``degrees`` – its rotation on the page (0, 90,
  180 or 270).

``region`` is read-only: attachments are shared by every skin and skeleton of the skeleton data, so they are never
remapped in place. Writing it raises
``SpineAttachment: property 'region' is read-only; use attachment:copy{ region = … }``.
Use ``attachment:copy{ region = "<name>" }`` (:doc:`copy`) for an attachment that shows another region.

Example
-------

.. code-block:: lua

   local region = skeleton:findSlot("gun").attachment.region
   print(region.name, region.x, region.y, region.width, region.height)
