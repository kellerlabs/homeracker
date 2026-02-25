// HomeRacker - Core Connector
//
// This model is part of the HomeRacker - Core system.
//
// MIT License
// Copyright (c) 2025 Patrick Pötz
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


// TODO: 1D1W is completely useless if not a pull-through connector. we should account for that.

include <BOSL2/std.scad>
include <constants.scad>

connector_outer_side_length = BASE_UNIT + BASE_STRENGTH*2 + TOLERANCE;
arm_side_length_inner = connector_outer_side_length - BASE_STRENGTH*2;

core_to_arm_translation = BASE_UNIT;

// Connector arm configuration lookup table
// Format: [dimensions][ways-1] = [+z, -z, +x, -x, +y, -y]
// Axis priority: Z → X → Y
// Direction priority: + before -
CONNECTOR_CONFIGS = [
    // 1D configurations (1-2 ways, Z-axis only)
    [
        [true, false, false, false, false, false],  // 1D1W: +Z
        [true, true, false, false, false, false]    // 1D2W: +Z, -Z
    ],
    // 2D configurations (2-4 ways, Z and X axes)
    [
        [true, false, true, false, false, false],   // 2D2W: +Z, +X
        [true, true, true, false, false, false],    // 2D3W: +Z, -Z, +X
        [true, true, true, true, false, false]      // 2D4W: +Z, -Z, +X, -X
    ],
    // 3D configurations (3-6 ways, all three axes)
    [
        [true, false, true, false, true, false],    // 3D3W: +Z, +X, +Y
        [true, true, true, false, true, false],     // 3D4W: +Z, -Z, +X, +Y
        [true, true, true, true, true, false],      // 3D5W: +Z, -Z, +X, -X, +Y
        [true, true, true, true, true, true]        // 3D6W: +Z, -Z, +X, -X, +Y, -Y
    ]
];

/**
  * HomeRacker Connector Module
  *
  * Parameters:
  *   dimensions (int, default=3): Number of dimensions the connector spans.
  *       - Valid range: 1 to 3.
  *   directions (int, default=3): Number of directions the connector has.
  *       - Valid ranges:
  *         - 1 to 2 when dimensions = 1.
  *         - 2 to 4 when dimensions = 2.
  *         - 3 to 6 when dimensions = 3.
  *       - No worries, invalid dimension/direction combinations will be corrected to the min/max valid values.
  *   pull_through_axis (string, default="none"): Axis along which items can be pulled through.
  *       - Options: "none", "x", "y", "z".
  *   is_foot (bool, default=false): If true, configures the connector as a foot piece.
  *       - Note: If set to true, it overrides pull_through_axis when set to "z".
  *   optimal_orientation (bool, default=false): If true, rotates the connector for optimal print orientation.
  *
  * Produces:
  *   A connector piece for the HomeRacker modular rack system.
  *   The connector can span multiple dimensions and directions, with optional pull-through functionality.
  *
  * Usage:
  *   connector_piece = homeRackerConnector(dimensions=2, directions=4, pull_through_axis="y", is_foot=false);
  */

module connector(dimensions=3, directions=6, pull_through_axis="none", is_foot=false, optimal_orientation=false) {

  // Validate and correct dimensions (1-3)
  valid_dimensions = max(1, min(3, dimensions));

  // Determine valid direction range based on dimensions
  min_directions = valid_dimensions == 1 ? 1 : valid_dimensions;
  max_directions = valid_dimensions * 2;

  // Validate and correct directions
  valid_directions = max(min_directions, min(max_directions, directions));

  // Get arm configuration from lookup table
  // Array index: [dimensions-1][directions-min_directions]
  config = CONNECTOR_CONFIGS[valid_dimensions - 1][valid_directions - min_directions];

  // for nicer optics, mirror the whole connector along the xy plane when it's a foot


  // Subtract Pull-Through Hole if applicable
  difference() {
    // Combine connector with Printing interfaces
    union() {
      if (valid_directions > 4) {
        // 5-6 way connectors: tetrahedron at chamfered corner
        rotation_1 = optimal_orientation ? [-(180 - acos(1/sqrt(3))),0,0] : [0,0,0];
        rotation_2 = optimal_orientation ? [0,0,45] : [0,0,0];
        rotate(rotation_1) rotate(rotation_2)
        difference() {
          union() {
            connector_raw(config, is_foot);
            print_interface_3d();
          }
          pull_through_hole(pull_through_axis, is_foot);
        }
      } else if (valid_directions == 4 && valid_dimensions == 2) {
        rotation = optimal_orientation ? [0,-135,0] : [0,0,0];
        rotate(rotation)
        difference() {
          connector_raw(config, is_foot);
          pull_through_hole(pull_through_axis, is_foot);
        }

      } else {
        // All other cases: simple flat base with chamfered edge
        rotation = optimal_orientation ? [90,-45,0] : [0,0,0];
        rotate(rotation)
        difference() {
          intersection() {
            connector_raw(config, is_foot);
            print_interface_base();
          }
          pull_through_hole(pull_through_axis, is_foot);
        }
      }
    }
  }
}

module connector_raw(config, is_foot=false) {
  difference() {
    // Core + Outer Arms
    union() {
      // Create connector core
      connectorCore();

      // Place arms based on configuration
      // Order: +Z, -Z, +X, -X, +Y, -Y
      if (config[0]) translate([0, 0, core_to_arm_translation]) connectorArmOuter(is_foot);  // +Z
      if (config[1]) translate([0, 0, -core_to_arm_translation]) rotate([180, 0, 0]) connectorArmOuter();  // -Z
      if (config[2]) translate([core_to_arm_translation, 0, 0]) rotate([0, 90, 0]) connectorArmOuter();  // +X
      if (config[3]) translate([-core_to_arm_translation, 0, 0]) rotate([0, -90, 0]) connectorArmOuter();  // -X
      if (config[4]) translate([0, core_to_arm_translation, 0]) rotate([-90, 0, 0]) connectorArmOuter();  // +Y
      if (config[5]) translate([0, -core_to_arm_translation, 0]) rotate([90, 0, 0]) connectorArmOuter();  // -Y
    }
    // Subract Inner Arms
    // Order: +Z, -Z, +X, -X, +Y, -Y
    if (config[0] && !is_foot) translate([0, 0, core_to_arm_translation]) connectorArmInner();  // +Z
    if (config[1]) translate([0, 0, -core_to_arm_translation]) rotate([180, 0, 0]) connectorArmInner();  // -Z
    if (config[2]) translate([core_to_arm_translation, 0, 0]) rotate([0, 90, 0]) connectorArmInner();  // +X
    if (config[3]) translate([-core_to_arm_translation, 0, 0]) rotate([0, -90, 0]) connectorArmInner();  // -X
    if (config[4]) translate([0, core_to_arm_translation, 0]) rotate([-90, 0, 0]) connectorArmInner();  // +Y
    if (config[5]) translate([0, -core_to_arm_translation, 0]) rotate([90, 0, 0]) connectorArmInner();  // -Y
  }
}


/** * Connector Arm Modules
  *
  * Produces a single arm of the connector to define the outer geometry.
  * It also creates the lock pin holes.
  */
module connectorArmOuter(is_foot=false) {

  arm_dimensions_outer = [connector_outer_side_length, connector_outer_side_length, BASE_UNIT];
  arm_side_length_inner = connector_outer_side_length - BASE_STRENGTH*2;
  arm_dimensions_inner = [arm_side_length_inner, arm_side_length_inner, BASE_UNIT];

  // outer cuboid
  difference() {
    color(HR_YELLOW) cuboid(arm_dimensions_outer, chamfer=BASE_CHAMFER,except=BOTTOM);
    if(!is_foot){
      color(HR_RED) rotate([90, 0, 0]) cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, connector_outer_side_length + EPSILON], chamfer=-LOCKPIN_HOLE_CHAMFER);
      color(HR_RED) rotate([90, 0, 90]) cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, connector_outer_side_length + EPSILON], chamfer=-LOCKPIN_HOLE_CHAMFER);
    }
  }
}

/** * Connector Arm Inner Module
  *
  * Produces a single arm of the connector to define the inner cutout.
  * When you difference() this with the outer arm, you get the hollow arm structure.
  */
module connectorArmInner() {

  arm_dimensions_inner = [arm_side_length_inner, arm_side_length_inner, BASE_UNIT + EPSILON];
  color(HR_GREEN)
  cuboid(arm_dimensions_inner, chamfer=BASE_CHAMFER,edges=BOTTOM);
}

/** * Connector Core Module
  *
  * Produces the core block of the connector.
  * Around it, the arms are attached.
  */
module connectorCore() {
  core_dimensions = [connector_outer_side_length, connector_outer_side_length, connector_outer_side_length];
  color(HR_BLUE)
  cuboid(core_dimensions, chamfer=BASE_CHAMFER);
}

/** * 3D Print Interface Module
  * Produces a tetrahedral shape that fits into the chamfered corner of the connector.
  * Used to provide enough surface area for 3D printing when the connector has multiple arms (5 or 6)
  */
module print_interface_3d() {
  // Create a tetrahedron by defining 4 vertices
  // Right angle at origin, edges along +X, +Y, +Z axes
  side_length = BASE_UNIT - TOLERANCE/2 - BASE_STRENGTH/2;
  // Position tetrahedron at chamfered corner: from center to outer edge, minus chamfer offset
  translation = connector_outer_side_length/2 - BASE_CHAMFER;
  points = [
    [0, 0, 0],              // Origin (right angle corner)
    [side_length, 0, 0],      // Along X axis
    [0, side_length, 0],      // Along Y axis
    [0, 0, side_length]       // Top point (apex)
  ];

  // Define the 4 triangular faces
  faces = [
    [0, 2, 1],  // Bottom face (XY plane triangle)
    [0, 1, 3],  // XZ plane face
    [0, 3, 2],  // YZ plane face
    [1, 2, 3]   // Hypotenuse face (slanted)
  ];

  color(HR_CHARCOAL)
  translate([translation, translation, translation])
  polyhedron(points=points, faces=faces, convexity=2);
}

/** * Base Print Interface Module
  * Produces a simple flat base with double-chamfered edge for print bed adhesion.
  * Used for most connector configurations (1-3 way connectors and 2D3W).
  */
module print_interface_base() {
  base_height = BASE_UNIT * 3;
  side_length = connector_outer_side_length *2;
  chamfer = BASE_CHAMFER * 3;

  // Position the base below the connector core
  //translate([0, 0, -base_height/2 - connector_outer_side_length/2])
  color(HR_CHARCOAL)
    // Main base cuboid with standard chamfer
  translate([connector_outer_side_length/2,connector_outer_side_length/2,0])
  cuboid([side_length, side_length, base_height], chamfer=chamfer, edges=LEFT+FRONT);
}

/* Pull-Through Hole Module
  *
  * Produces a pull-through hole along the specified axis.
  */
module pull_through_hole(axis="none", is_foot=false) {
  // Determine hole orientation and dimensions based on axis
  hole_length = BASE_UNIT * 3;
  hole_dimensions = [hole_length, arm_side_length_inner, arm_side_length_inner];

  color(HR_WHITE)
  if (axis == "y") {
    rotate([0, 0, 90])
    cuboid(hole_dimensions);
  } else if (axis == "z" && !is_foot) {
    rotate([0, -90, 0])
    cuboid(hole_dimensions);
  } else if (axis == "x") {
    cuboid(hole_dimensions);
  }
}
