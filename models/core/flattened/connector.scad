include <BOSL2/std.scad>

/* [Parameters] */

// Dimensions of the connector (between 1-3)
dimensions = 3; // [1:1:3]

// Directions of the connector (between 1-6)
directions = 3; // [1:1:6]

// Pull-through axis (none, x,y,z)
pull_through_axis = "none"; // ["none","x","y","z"]

// Optimal Printing Orientation
optimal_orientation = true; // [true,false]

/* [Hidden] */
// --- from constants.scad ---
TOLERANCE = 0.2;
BASE_UNIT = 15;
BASE_STRENGTH = 2;
BASE_CHAMFER = 1;
LOCKPIN_HOLE_CHAMFER = 0.8;
LOCKPIN_HOLE_SIDE_LENGTH = 4;
HR_YELLOW = "#f7b600";
HR_BLUE = "#0056b3";
HR_RED = "#c41e3a";
HR_GREEN = "#2d7a2e";
HR_CHARCOAL = "#333333";
HR_WHITE = "#f0f0f0";
// --- from connector.scad ---
connector_outer_side_length = BASE_UNIT + BASE_STRENGTH*2 + TOLERANCE;
arm_side_length_inner = connector_outer_side_length - BASE_STRENGTH*2;
core_to_arm_translation = BASE_UNIT;
CONNECTOR_CONFIGS = [

    [
        [true, false, false, false, false, false],
        [true, true, false, false, false, false]
    ],

    [
        [true, false, true, false, false, false],
        [true, true, true, false, false, false],
        [true, true, true, true, false, false]
    ],

    [
        [true, false, true, false, true, false],
        [true, true, true, false, true, false],
        [true, true, true, true, true, false],
        [true, true, true, true, true, true]
    ]
];
$fn = 100;

// Color based on configuration:
// HR_GREEN - standard (no pull through)
// HR_YELLOW - pull-through (x/y/z pull through)
module connector(dimensions=3, directions=6, pull_through_axis="none", optimal_orientation=false) {

  valid_dimensions = max(1, min(3, dimensions));

  min_directions = valid_dimensions == 1 ? 1 : valid_dimensions;
  max_directions = valid_dimensions * 2;

  valid_directions = max(min_directions, min(max_directions, directions));

  config = CONNECTOR_CONFIGS[valid_dimensions - 1][valid_directions - min_directions];

  difference() {

    union() {
      if (valid_directions > 4) {

        rotation_1 = optimal_orientation ? [-(180 - acos(1/sqrt(3))),0,0] : [0,0,0];
        rotation_2 = optimal_orientation ? [0,0,45] : [0,0,0];
        rotate(rotation_1) rotate(rotation_2)
        difference() {
          union() {
            connector_raw(config);
            print_interface_3d();
          }
          pull_through_hole(pull_through_axis);
        }
      } else if (valid_directions == 4 && valid_dimensions == 2) {
        rotation = optimal_orientation ? [0,-135,0] : [0,0,0];
        rotate(rotation)
        difference() {
          connector_raw(config);
          pull_through_hole(pull_through_axis);
        }

      } else {

        rotation = optimal_orientation ? [90,-45,0] : [0,0,0];
        rotate(rotation)
        difference() {
          intersection() {
            connector_raw(config);
            print_interface_base();
          }
          pull_through_hole(pull_through_axis);
        }
      }
    }
  }
}
module connector_raw(config) {
  difference() {

    union() {

      connectorCore();

      if (config[0]) translate([0, 0, core_to_arm_translation]) connectorArmOuter();
      if (config[1]) translate([0, 0, -core_to_arm_translation]) rotate([180, 0, 0]) connectorArmOuter();
      if (config[2]) translate([core_to_arm_translation, 0, 0]) rotate([0, 90, 0]) connectorArmOuter();
      if (config[3]) translate([-core_to_arm_translation, 0, 0]) rotate([0, -90, 0]) connectorArmOuter();
      if (config[4]) translate([0, core_to_arm_translation, 0]) rotate([-90, 0, 0]) connectorArmOuter();
      if (config[5]) translate([0, -core_to_arm_translation, 0]) rotate([90, 0, 0]) connectorArmOuter();
    }

    if (config[0]) translate([0, 0, core_to_arm_translation]) connectorArmInner();
    if (config[1]) translate([0, 0, -core_to_arm_translation]) rotate([180, 0, 0]) connectorArmInner();
    if (config[2]) translate([core_to_arm_translation, 0, 0]) rotate([0, 90, 0]) connectorArmInner();
    if (config[3]) translate([-core_to_arm_translation, 0, 0]) rotate([0, -90, 0]) connectorArmInner();
    if (config[4]) translate([0, core_to_arm_translation, 0]) rotate([-90, 0, 0]) connectorArmInner();
    if (config[5]) translate([0, -core_to_arm_translation, 0]) rotate([90, 0, 0]) connectorArmInner();
  }
}
module connectorArmOuter() {

  arm_dimensions_outer = [connector_outer_side_length, connector_outer_side_length, BASE_UNIT];
  arm_side_length_inner = connector_outer_side_length - BASE_STRENGTH*2;
  arm_dimensions_inner = [arm_side_length_inner, arm_side_length_inner, BASE_UNIT];

  difference() {
    color(HR_YELLOW) cuboid(arm_dimensions_outer, chamfer=BASE_CHAMFER,except=BOTTOM);
    color(HR_RED) rotate([90, 0, 0]) cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, connector_outer_side_length], chamfer=-LOCKPIN_HOLE_CHAMFER);
    color(HR_RED) rotate([90, 0, 90]) cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, connector_outer_side_length], chamfer=-LOCKPIN_HOLE_CHAMFER);
  }
}
module connectorArmInner() {

  arm_dimensions_inner = [arm_side_length_inner, arm_side_length_inner, BASE_UNIT];
  color(HR_GREEN)
  cuboid(arm_dimensions_inner, chamfer=BASE_CHAMFER,edges=BOTTOM);
}
module connectorCore() {
  core_dimensions = [connector_outer_side_length, connector_outer_side_length, connector_outer_side_length];
  color(HR_BLUE)
  cuboid(core_dimensions, chamfer=BASE_CHAMFER);
}
module print_interface_3d() {

  side_length = BASE_UNIT - TOLERANCE/2 - BASE_STRENGTH/2;

  translation = connector_outer_side_length/2 - BASE_CHAMFER;
  points = [
    [0, 0, 0],
    [side_length, 0, 0],
    [0, side_length, 0],
    [0, 0, side_length]
  ];

  faces = [
    [0, 2, 1],
    [0, 1, 3],
    [0, 3, 2],
    [1, 2, 3]
  ];

  color(HR_CHARCOAL)
  translate([translation, translation, translation])
  polyhedron(points=points, faces=faces, convexity=2);
}
module print_interface_base() {
  base_height = BASE_UNIT * 3;
  side_length = connector_outer_side_length *2;
  chamfer = BASE_CHAMFER * 3;

  color(HR_CHARCOAL)

  translate([connector_outer_side_length/2,connector_outer_side_length/2,0])
  cuboid([side_length, side_length, base_height], chamfer=chamfer, edges=LEFT+FRONT);
}
module pull_through_hole(axis="none") {

  hole_length = BASE_UNIT * 3;
  hole_dimensions = [hole_length, arm_side_length_inner, arm_side_length_inner];

  color(HR_WHITE)
  if (axis == "y") {
    rotate([0, 0, 90])
    cuboid(hole_dimensions);
  } else if (axis == "z") {
    rotate([0, -90, 0])
    cuboid(hole_dimensions);
  } else if (axis == "x") {
    cuboid(hole_dimensions);
  }
}

function get_connector_color(pull_through_axis="none") =
  pull_through_axis != "none" ? HR_YELLOW :
  HR_GREEN;

color(get_connector_color(pull_through_axis))
connector(dimensions, directions, pull_through_axis, optimal_orientation);
