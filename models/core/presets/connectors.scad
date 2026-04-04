// HomeRacker - Connector Release Variants
//
// This is an opinionated collection of useful connector variants for
// export and release. It includes standard connectors and
// pull-through connectors as separate modules.

include <../main.scad>

/* [Hidden] */
$fn = 100;
// Spacing between connectors (mm)
spacing = BASE_UNIT*3 + BASE_STRENGTH; // [20:5:40]

// Grid layout helper
module grid_position(row, col) {
    translate([col * spacing, row * spacing, 0])
        children();
}

module connectors_standard(optimal_orientation=false) {
  // Row 0: 1D variants
  grid_position(0, 0) connector(1, 2, "none", optimal_orientation);

  // Row 1: 2D variants
  grid_position(1, 0) connector(2, 2, "none", optimal_orientation);
  grid_position(1, 1) connector(2, 3, "none", optimal_orientation);
  grid_position(1, 2) connector(2, 4, "none", optimal_orientation);

  // Row 2: 3D variants
  grid_position(2, 0) connector(3, 3, "none", optimal_orientation);
  grid_position(2, 1) connector(3, 4, "none", optimal_orientation);
  grid_position(2, 2) connector(3, 5, "none", optimal_orientation);
  grid_position(2, 3) connector(3, 6, "none", optimal_orientation);
}

module connectors_pull_through(optimal_orientation=false) {
  // Row 0: 1D pull-through variants
  grid_position(0, 0) connector(1, 1, "x", optimal_orientation);
  grid_position(0, 1) connector(1, 2, "x", optimal_orientation);

  // Row 1: 2D pull-through variants
  grid_position(1, 0) connector(2, 2, "x", optimal_orientation);
  grid_position(1, 1) connector(2, 2, "y", optimal_orientation);
  grid_position(1, 2) connector(2, 3, "x", optimal_orientation);
  grid_position(1, 3) connector(2, 3, "y", optimal_orientation);
  grid_position(1, 4) connector(2, 3, "z", optimal_orientation);
  grid_position(1, 5) connector(2, 4, "x", optimal_orientation);
  grid_position(1, 6) connector(2, 4, "y", optimal_orientation);

  // Row 2: 3D pull-through variants
  grid_position(2, 0) connector(3, 3, "x", optimal_orientation);
  grid_position(2, 1) connector(3, 4, "x", optimal_orientation);
  grid_position(2, 2) connector(3, 4, "z", optimal_orientation);
  grid_position(2, 3) connector(3, 5, "x", optimal_orientation);
  grid_position(2, 4) connector(3, 5, "y", optimal_orientation);
  grid_position(2, 5) connector(3, 6, "x", optimal_orientation);
}


// Create grid of all standard connectors
// connectors_standard(true);
// connectors_pull_through(true);
