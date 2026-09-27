// HomeRacker - Support Release Variants
//
// This is an opinionated collection of useful support variants for
// export and release. It includes basic supports with standard holes
// and supports with x-holes for printbed interface.

include <../main.scad>

/* [Hidden] */
$fn = 100;
// Spacing between supports (mm)
spacing = BASE_UNIT + BASE_STRENGTH;  // Distance along x-axis

// Linear layout helper
module linear_position(index) {
  translate([index * spacing, 0, 0])
    children();
}

module basic(amount = 17, x_holes = false) {
  for (i = [1:amount - 1]) {
    linear_position(i) support(i + 1, x_holes);
  }
}

// Example calls
// basic(17, false);  // Standard holes
// basic(17, true);   // Double holes
