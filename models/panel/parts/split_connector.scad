// HomeRacker - Split Connector
//
// Hinge-knuckle connector that joins two split rack panel halves.
// Each height unit carries 4 interleaved knuckles (LOCK + 2 MIDDLE + LOCK),
// so both halves own two knuckles each. Normally generated as part of a split
// panel; this part exposes it standalone for preview and inspection.
// Lock the assembled hinge with a matching Split Lock Pin.

include <../lib/split.scad>

/* [Parameters] */
// Connector height in rack units (match the split panel)
height_units = 1; // [1:1:8]
// Which knuckles to keep: all (both halves), or just one panel half's knuckles
knuckle_side = "all"; // [all:Both halves, left:Left half, right:Right half]

/* [Debug Parameters] */
// Show distinct colors per section for easier debugging
debug_colors = false; // [false,true]
// Enable chamfering on the knuckle edges
chamfer_enabled = true; // [false,true]

/* [Hidden] */
$fn = 100;

split_connector(units=height_units, knuckle_side=knuckle_side,
  debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
