===================================
skeleton.fill.effect and tint black
===================================

| **Type:** effect ``userdata`` or ``nil``; write a ``string`` or ``nil``
| **See also:** :doc:`../fill`, :doc:`effect/name`, :doc:`../setFillColor`, :doc:`../slot/darkColor`

Overview
--------

A skeleton draws with Solar2D meshes, and ``skeleton.fill.effect`` applies a Solar2D
`shader effect <https://docs.coronalabs.com/guide/graphics/effects.html>`_ to all of them, as on any
display object. Effect attributes written on the skeleton reach every mesh, and ``nil`` removes the effect:

.. code-block:: lua

   spineboy.fill.effect = "filter.desaturate"
   spineboy.fill.effect.intensity = 0.5

   -- later
   spineboy.fill.effect = nil

Reading ``skeleton.fill.effect`` returns ``nil`` while no effect is set, and otherwise an effect object. Its
:doc:`effect/name` is the effect's name, and every other key is an effect attribute:

- Writing an attribute sets it on every mesh of the skeleton. The value is a number, or a table of numbers for a
  vector attribute; ``nil`` removes the attribute. Any other value raises
  ``Effect attribute '<key>' must be a number, table of numbers, or nil``, and a table holding something other than
  a number raises ``Effect attribute array must contain only numbers (index <i>)``.
- Reading an attribute returns the value you wrote through the skeleton, or ``nil``: the effect's own default values
  are not read back.

Writing ``skeleton.fill.effect`` a value other than a string or ``nil`` raises
``fill.effect expects nil or string (effect name)``.

.. toctree::
   :maxdepth: 1

   name <effect/name>

The plugin also uses a shader effect of its own to draw **tint black**, described below. The two cannot be
combined on one skeleton.

**Tint black**

Spine's tint black (two-colour tint) gives a slot a second, dark colour: the texture's darkest parts take the
dark colour while its lightest parts keep the slot colour. The plugin draws it like the Spine runtimes do:
``rgb = texture.rgb * color.rgb + (texture.a - texture.rgb) * dark.rgb``. A slot whose dark colour is black
draws exactly like a slot without one. Read a slot's dark colour with :doc:`../slot/darkColor`.

The plugin draws the meshes of slots with a dark colour other than black with the effect
``filter.custom.plugin_spine_tintBlack``. It defines this effect with ``graphics.defineEffect`` the first time
a skeleton draws such a slot, once per Lua state.

- **The effect name is reserved.** Do not define ``filter.custom.plugin_spine_tintBlack`` in your app. If your
  app defines it first, Solar2D logs
  ``ERROR: Could not create custom effect. An effect (custom.plugin_spine_tintBlack) for category (filter) already exists!``
  when the plugin defines it, and the plugin cannot detect this: slots with a dark colour are then drawn with your
  effect.
- **If the effect cannot be defined, tint black is off.** When ``graphics.defineEffect`` raises an error, the plugin
  prints one ``WARNING: plugin.spine: could not define filter.custom.plugin_spine_tintBlack, tint black is off: ...``
  line and draws every slot without its dark colour, as version 1.5.0 did. It never raises.

**A skeleton fill effect wins**

While ``skeleton.fill.effect`` is set, no mesh of that skeleton draws tint black: slots with a dark colour draw
without it. On the next draw after ``skeleton.fill.effect = nil``, tint black is back. So a hit flash
(for example ``filter.brightness``) or ``filter.desaturate`` works on a skeleton with dark colours, but it
cannot be combined with tint black: during the flash, the dark colours are not drawn.

**Exporting art with dark colours**

- **Export atlases with straight alpha.** Leave "Premultiply alpha" off when you pack the atlas; Solar2D
  premultiplies textures when it loads them. Premultiplied-alpha atlases are not supported.
- **The dark colour is not multiplied by the slot's attachment or skeleton colour.** The plugin follows the
  Spine C++ and TypeScript runtimes here. libGDX and the Spine editor multiply the dark colour by those colours,
  so art whose attachment or skeleton colour is not white can look different in the editor.
- **Dark colours are rounded to the nearest level.** The runtime converts the dark colour to bytes by rounding each
  channel to the nearest level (1/255), also while an animation fades it between keys.
