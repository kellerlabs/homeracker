# Crates

A parametric module for rugged, stackable crates designed for the HomeRacker ecosystem.
These crates can function as standalone rugged storage or integrate seamlessly with both Gridfinity and HomeRacker frameworks.

## Features Checklist

- [ ] **Rugged & Stable:** High durability design with robust walls and structure.
- [ ] **Stackable:** Crate edges and bases lock securely into each other when stacked.
- [ ] **Gridfinity Compatibility (Opt-in):**
  - Inner dimensions can be customized to accept standard Gridfinity inserts.
  - Optional Gridfinity base profile for the bottom of the crate.
- [ ] **HomeRacker Compatibility (Opt-in):**
  - Functions as a simple drawer system.
  - Two contact points protrude from the bottom of the crate, allowing it to slide into a HomeRacker frame and hook in place once settled.
- [ ] **Combinable Options:** Features can be mixed and matched as needed via parameters.

### Planned for Later
- [ ] **Lids:** Snap-on or hinged lids to enclose the crates.

## Design Inspiration & Alternatives

Before building this from scratch, we reviewed existing online solutions to see how they approach rugged, stackable storage:

1. **Gridfinity Rugged Box (Parametric) / Rugged Cases:**
   - *What they do well:* Highly popular parametric designs on Printables and MakerWorld. They usually incorporate hinges, latches (often requiring M3 screws), and gaskets for a fully enclosed, heavy-duty feel.
   - *Why we might build our own:* The existing ones are primarily designed as portable latched cases rather than open drawer/crate systems. They lack the specific bottom-hook geometry needed for a clean sliding fit into a HomeRacker scaffold.
2. **Rugged Stackable Gridfinity Bins:**
   - *What they do well:* Taller, reinforced bins designed to stack independently while still slotting into a Gridfinity baseplate.
   - *Why we might build our own:* While good for stacking, we need a bespoke integration method (protruding hooks) to mount directly onto HomeRacker rails securely.

By building our own `crates` module, we can achieve native integration with the HomeRacker scaffolding (the sliding drawer mechanic) while borrowing the rugged aesthetic and stackability that makes the Gridfinity rugged boxes so popular.
