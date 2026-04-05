// HomeRacker - Support
//
// Fully customizable support beam part.

// Use the main homeracker library file
include <../main.scad>

/* [Parameters] */

// The length (Y-axis) of the support in base units.
units = 3; // [1:1:50]

// Add x holes
x_holes = false;

/* [Debug Parameters] */
debug_colors = false; // If true, uses bright colors to visualize different features (e.g. holes, main body) for testing purposes.
disable_chamfer = false; // If true, disables chamfered edges for debugging and testing.

/* [Hidden] */
$fn = 100;

// --- Examples ---

// Example 1: Create a default support (uses default units and x_holes)
// support();

// Example 2: Create a support with 5 units and no x holes
// support(units=5, x_holes=false);

// Example 3: Create a support with units and x_holes as set above
support(units=units, x_holes=x_holes, debug_colors=debug_colors, disable_chamfer=disable_chamfer);
