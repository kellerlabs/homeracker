// HomeRacker - Racklink Test
//
// Test file for racklink module.

include <../lib/racklink.scad>

// Default: full-coverage sleeves, single-unit distance
racklink(height=3, distance=1);

// Custom sleeve range: left sleeve covers units 1–3 of a 5-unit racklink
right(80)
racklink(height=5, distance=1, left_start=1, left_end=3);

// Clamped end: left_end exceeds height, clamped to height
right(160)
racklink(height=3, distance=1, left_start=1, left_end=20);

// Ignored range: start >= end falls back to full coverage
right(240)
racklink(height=3, distance=1, left_start=5, left_end=2);

// Negative start: left sleeve shifted down (misaligned columns)
right(320)
racklink(height=5, distance=1, left_start=-2, left_end=3);

// Asymmetric: different ranges per side
right(400)
racklink(height=5, distance=2, left_start=-2, left_end=3, right_start=1, right_end=4);
