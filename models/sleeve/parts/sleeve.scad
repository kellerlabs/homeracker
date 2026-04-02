// HomeRacker - Sleeve
// 3-sided U-shaped sleeve that wraps around a vertical HomeRacker support.

include <../lib/sleeve.scad>

/* [General] */
// height of the sleeve in HomeRacker units
length = 3; // [1:1:20]

/* [Debug Parameters] */
debug_colors = false; // [false,true]
disable_chamfer = false; // [false,true]

/* [Hidden] */
$fn = 100;

sleeve(length, debug_colors=debug_colors, disable_chamfer=disable_chamfer);
