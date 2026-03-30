// HomeRacker - Racklink
// Connects independent rack columns together via double U-shaped sleeves.

include <../lib/racklink.scad>

/* [General] */
// height of the HomeRacker supports to be covered in HomeRacker units (use the taller one if the rack columns have different heights)
height = 3; // [1:1:20]

/* [Advanced Parameters] */
// horizontal distance between the two u-shapes in HomeRacker units
distance = 1; // [1:1:5]
// start of the left u-shape in units. 0 = centered (full coverage). A valid value shifts the sleeve upward from center. Ignored (falls back to full coverage) if start >= end or start >= height.
left_start = 0; // [-10:1:19]
// end of the left u-shape in units. Clamped to height if it exceeds it. Ignored (falls back to full coverage) if start >= end.
left_end = 20; // [0:1:20]
// start of the right u-shape in units. 0 = centered (full coverage). A valid value shifts the sleeve upward from center. Ignored (falls back to full coverage) if start >= end or start >= height.
right_start = 0; // [-10:1:19]
// end of the right u-shape in units. Clamped to height if it exceeds it. Ignored (falls back to full coverage) if start >= end.
right_end = 20; // [0:1:20]

/* [Debug Parameters] */
debug_colors = false; // [false,true]
disable_chamfer = false; // [false,true]

/* [Hidden] */
$fn = 100;

racklink(height, distance, left_start, left_end, right_start, right_end, debug_colors, disable_chamfer);
