// HomeRacker - Support
//
// Fully customizable support beam part.

// Use the main homeracker library file
include <../main.scad>

units = 17;
x_holes = true;
support(units=units, x_holes=x_holes);

// Truss-width support (14mm narrow, no x_holes)
translate([30, 0, 0])
support(units=3, x_holes=false, width=HR_SUPPORT_WIDTH_TRUSS);
