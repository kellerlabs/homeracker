// HomeRacker - Truss Collar
//
// Fully customizable truss collar part.

include <../lib/truss_collar.scad>

/* [Parameters] */

// The length (Y-axis) of the collar in base units (min 4 for brick bond).
units = 4; // [4:1:50]

/* [Debug Parameters] */
debug_colors = false; // If true, uses bright colors to visualize different features.
disable_chamfer = false; // Reserved for future use.

/* [Hidden] */
$fn = 100;

truss_collar(units=units, debug_colors=debug_colors, disable_chamfer=disable_chamfer);
