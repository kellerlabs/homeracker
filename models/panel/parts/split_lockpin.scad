// HomeRacker - Split Lock Pin
//
// Extended lock pin that joins two split rack panel halves.
// Threads vertically through the panel's split connector and locks
// the hinge closed. Print one per split panel; pick the same height
// units as the panel it locks.

include <../lib/split.scad>

/* [Parameters] */
// Panel height in rack units (match the split panel this pin locks)
height_units = 1; // [1:1:8]

/* [Debug Parameters] */
// Show distinct colors per section for easier debugging
debug_colors = false; // [false,true]
// Enable chamfering on the insertion ends
chamfer_enabled = true; // [false,true]

/* [Hidden] */
$fn = 100;

split_lockpin(units=height_units,
  debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
