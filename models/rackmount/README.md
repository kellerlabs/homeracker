## Raw version to be refined/reworked by agent

This model contains rackmount adapter (haven't found a better word for it. open to renaming it) to connect the HomeRacker system with standardized rackmount components (primarily 10" and 19" but should also enable any" racks following the same mechanic).

These adapters are the successors to the initial [10"](https://makerworld.com/en/models/1353730-modular-10-server-rack#profileId-1396918) and [19"](https://makerworld.com/en/models/1503491-modular-19-server-rack#profileId-1573137) rackmount adapters I uploaded to makerworld in 2025.

Why replace them:
1. They are in their basic building block form not open source -> doesn't follow my current principles
2. They have been created using Fusion 360 -> hard to maintain.
3. Due to their design, they need to be mounted on y-axis supports which
  * force you to use pull-through connectors which makes planning hard, as this is not obvious to spot from ready-built model photos
  * protrudes 2 entire units in front of the rack which feels very alien to build for the community (see Discord)
  * force you to build bottom-up (staircase design -> adjoining rackmounts share the same y-axis support) which needs meticulous planning upfront and doesn't allow for easy maintenance or future attachments
4. Only supported 2 standards -> 10 and 19 inch. The new ones will likely support any inch racks following a system.
5. An ugly unaccounted gap between rackmount adapters

HomeRacker was initially designed to accomodate standard height unit devices easily while maintaining metric units.
That's why HomeRacker's base unit is 15mm. 3 Bas Units give you 45mm which is just above a standard rack unit of 44.45mm (I think. check this!).
This small gap comes with a trade-off though: the bigger your rackmount adapter gets, the more gap you will see to the next rackmount above.

I am opinionated in my design choices, meaning that I only create a rackmount big enough to accomodate a single device.
This comes with one big advantage: Support beams are placed directly under a device (in size variants that allow supports being printed in one piece!!) to bear it's load. that takes off the main load from the front mount and distributes it across support beams under it -> great stability. Again, this only works when the support beams can be printed in a single piece. Otherwise I highly discourage you from doing that.
Anyways, this also comes with the trade-off, that there's a gap of one homeracker unit (+ the obvious homeracker-to-standard-unit gap per height unit. ~0.5mm per unit) between adapters.
This version though provides panels to close this gap for good for a better look, supporting airflow and dust protection at the same time.
Another advantage of this design choice is better heat dissipation as there is always at least a gap of one homeracker unit between devices.
You don't have to follow this opinionated design choice as both, the legacy and new version of the adapters can just be printed big enough (as much units as possible) to directly mount devices adjoining each others.

The new design is mounted differently:
Instead of requiring protruding y-axis supports, it is mounted on the vertical front supports. like a sleeve. It only protrudes one homeracker unit to accomodate the thick frontplate and eventual divergences in cage nut sizes. while not interfering with the outer connector walls (yes, it is pretty cozy there and not protruding would make cage nuts collide with the connector arm of the horizontal support. there is a tradeoff in every design I was able to come up with so far).
Anyhow, aside from the vertical front support mount via lockpin, the adapter also puts a "collar" (i really don't know how to name that. pls come up with something better here dear agent) along the inside of the adjoining connector arms as well. This is actually what gives the entire adapter stability and distributes the load onto the rack, not the sleeve mount with the lock pin. Why: because a single unit (standard units) would only have a single lockpn to mount on and I feared (yes feared, not measured or dared to try even) that this alone might break over time.
This design choice is in my point of view superior to the old one, because it allows to switch up the design of a single rack level at any position of the rack, not only the uppermost one. The old design forced you to lock the entire rack design by the adapter. no post-adaption possible. i love the idea (still need to proof it. as soon as i provide pictures in assets we can see this claim proven)
