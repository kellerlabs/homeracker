// HomeRacker - Foot Insert
//
// Fully customizable foot insert part.

include <../lib/foot.scad>

/* [Debug Parameters] */
// Show distinct colors per section for easier debugging and measurement
debug_colors = false; // [false,true]
// Disable chamfering for easier measurement and testing
disable_chamfer = false; // [false,true]

/* [Hidden] */
$fn = 100;

foot(debug_colors=debug_colors, disable_chamfer=disable_chamfer);
