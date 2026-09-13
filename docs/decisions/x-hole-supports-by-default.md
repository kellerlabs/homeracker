# 📋 Use supports with lock pin holes on both axes

## 📌 Status

**Accepted**: 2026-09-13

## 🤔 Context

`support()` takes an `x_holes` flag. Without it a support carries one set of lock pin holes, running across a single axis; with it there is a second set across the other axis.

A panel hangs on the holes of the supports that bound its opening. Its mount plates and corner brackets lie on the face a support turns towards the opening, and each hole runs across that face, so the axis a panel needs depends on the face it sits on:

- a front or back panel needs vertical holes along its top and bottom edges, and sideways holes through the posts along its left and right edges
- a shelf or top panel needs sideways holes in all four bounding supports

One set of holes serves one of those directions. The configurator exported plain supports and pinned everything along the single available axis, which left the panels it drew unfastened on half their edges.

## 🔧 Decision

Export and list every support with `x_holes=true`.

The alternative was to pick the variant per support, from the panels that touch it. It was rejected for now: it adds a second support part to every parts list, doubles the exported mesh library, and needs a rule for supports that end up in both roles, in return for holes nobody is forced to use.

Load bearing is the reason to revisit this. A second set of holes takes material out of the middle of every unit, and a support carrying a heavy shelf may prefer to keep it. When that case comes up, the choice becomes per support rather than a project-wide default.

## 📊 Consequences

- Every panel mount the configurator draws has a hole to pin to, on every edge.
- One support part instead of two, in the mesh library and in the parts list.
- The two holes of a cell cross in its middle, so a cell still takes only one pin. Where a front panel and a side panel meet at the same corner cell, one of the two corners stays unpinned; the configurator gives the pin to the axis that holds more brackets (`configurator/src/engine/pins.ts`).
- Supports are slightly weaker than the single-hole variant and take marginally longer to print.
- Anyone who has already printed plain supports can still use them; the second hole matters only where a panel is mounted.
