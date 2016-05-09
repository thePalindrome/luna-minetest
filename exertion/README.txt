Exertion Minetest Mod
=====================

Exertion is an attempt to add a small amount of realism and challenge, and
shift the balance of play a little more toward survival considerations such as
maintaining access to food and water.  You don't absolutely need to eat and
drink to survive, but you do need to eat and drink to function at full
efficiency.

Exertion tracks player activity and food and water consumption.  Starvation and
dehydration cause fatigue (reducing running speed and jump height) but do not
kill the player.  Healing isn't instantaneous when food is consumed, but occurs
over time if the player is well-fed and hydrated.  Being poisoned can cause
minor damage and major food and water loss over time, as the player vomits or
dry heaves.

The mod is very customizable.  Many settings can be changed in the
'settings.lua' file within the mod directory, and overridden on a per-world
basis in a 'exertion_settings.lua' file in the world directory (this file isn't
created automatically, but has the same syntax and setting values as the one in
the mod directory).  The default behavior of the mod is described below.

Food
----

Food does not cause instantanous changes in health (HP).  Instead, eating food
increases the "fed" meter, and being well-fed is a necessary condition for
healing.  The "fed" meter decreases over time, even when the player is logged
out.  When it is over half full, the player heals slowly over time (up to
4 hearts per day), provided other conditions such as being well-hydrated are
met.  The player is "starving" when the meter is empty.  This does not cause
damage, but does reduce running speed and jump height.

Water
-----

Like being well fed, the player must stay hydrated to heal and perform well.
Drinking water occurs automatically when the player is next to water (a water
source or flowing water node), provided his/her head is in air.  The "hydrated"
meter decreases over time, even when the player is logged out.  When it is over
half full, the player heals slowly over time, provided other conditions such as
being well-fed are met.  The player is "dehydrated" when the meter is empty.
This does not cause damage, but does reduce running speed and jump height (they
are doubly reduced if the player is both starving and dehydrated).

Poison
------

When eating toxic foods (which would normally cause reduction in health), or
occasionally when food has spoiled (small random chance when eating any food),
the player becomes poisoned.  This condition can last up to a Minetest day.
The "poisoned" meter decreases slowly over time, but, unlike the other meters,
only does so while the player is logged in.

While poisoned, running speed and jump height are reduced, healing does not
occur, and the player periodically retches (vomiting up food and water and
eventually losing small amounts of health; retching while holding one's breath
is also a very bad idea).  Exertion and being well-fed and hydrated all
increase the frequency of retching.  Retching does not occur when the player is
not logged in.

Exertion
--------

When moving around, holding his/her breath, and building (digging and placing
nodes), the player is considered to be undergoing light or heavy exertion.
The level of exertion influences the rate of food and water consumption
(doubling or tripling the rate that the "fed" and "hydrated" meters decrease)
and increases the likelihood of retching when poisoned.  Heavy exertion also
halves the rate of healing.

Light exertion is defined as moving and/or holding one's breath at least
one-quarter of the time, and/or building at least 5 nodes in a ten-second
period.  Heavy exertion is defined as moving and/or holding one's breath at
least three-quarters of the time, and/or building at least 10 nodes in a
ten-second period.

Mod Information
---------------

Required Minetest Version: >=0.4.12
    (may work as early as 0.4.10, but not tested)

Dependencies: (none)

Soft Depenencies: (none)

Highly Recommended: default, farming (and/or other mods that provide food)

Craft Recipies: (none)

Git Repo: https://github.com/prestidigitator/minetest-mod-exertion

Change History
--------------

Version 1.0

* Released 2015-04-06
* First working version.

Future Direction
----------------

* Provide a fix for physics overrides so that this mod can be better integrated
  with other mods that change running speed and jump height.  Perhaps a setting
  that defines a dynamic base speed/height which the multipliers then modify.
* Document the API.  For now, see the doc comments in settings.lua, init.lua,
  and PlayerState.lua.

Copyright and Licensing
-----------------------

Retching sounds (exertion_retching.ogg and exertion_doubleRetching.ogg) are
derived from the sound located at:

   http://freesound.org/people/mefrancis13/sounds/117605/

Both the original and derived sounds are licensed under CC0 1.0
(http://creativecommons.org/publicdomain/zero/1.0/).

All other content, including documentation, source code, and textures, are
original content created by the mod author and are licensed under WTFPL.

Author: prestidigitator (as registered on forum.minetest.net)
Licenses: CC0 1.0 (sounds), WTFPL (everything else)

