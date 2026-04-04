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
TOLERANCE = 0.2;
PRINTING_LAYER_WIDTH = 0.4;
PRINTING_LAYER_HEIGHT = 0.2;
BASE_UNIT = 15;
BASE_STRENGTH = 2;
BASE_CHAMFER = 1;
LOCKPIN_HOLE_CHAMFER = 0.8;
LOCKPIN_HOLE_SIDE_LENGTH = 4;
LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION = [LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH];
LP_GRIP_STANDARD = 0;
LP_GRIP_EXTENDED = 1;
LP_GRIP_NO_GRIP = 2;
LP_NECK_EXT_NONE = 0;
LP_NECK_EXT_NECK = 1;
LP_NECK_EXT_BOTH = 2;
LP_NECK_EXT_TAIL = 3;
LP_NECK_EXTENSION_UNIT = BASE_STRENGTH + TOLERANCE/2;
HR_YELLOW = "#f7b600";
HR_BLUE = "#0056b3";
HR_RED = "#c41e3a";
HR_GREEN = "#2d7a2e";
HR_CHARCOAL = "#333333";
HR_WHITE = "#f0f0f0";
STD_UNIT_HEIGHT = 44.45;
STD_UNIT_DEPTH = 482.6;
STD_WIDTH_10INCH = 254;
STD_WIDTH_19INCH = 482.6;
STD_MOUNT_SURFACE_WIDTH = 15.875;
STD_RACK_BORE_DISTANCE_Z = 15.875;
STD_RACK_BORE_DISTANCE_MARGIN_Z = 6.35;
tolerance = TOLERANCE;
printing_layer_width = PRINTING_LAYER_WIDTH;
printing_layer_height = PRINTING_LAYER_HEIGHT;
base_unit = BASE_UNIT;
base_strength = BASE_STRENGTH;
base_chamfer = BASE_CHAMFER;
lockpin_hole_chamfer = LOCKPIN_HOLE_CHAMFER;
lockpin_hole_side_length = LOCKPIN_HOLE_SIDE_LENGTH;
lockpin_hole_side_length_dimension = LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION;

HR_CORE_SUPPORT_PRIMARY_COLOR = HR_CHARCOAL;
module support(units=3, x_holes=false,
    debug_colors=false, disable_chamfer=false,
    anchor=CENTER, spin=0, orient=UP) {

    support_dimensions = [BASE_UNIT, BASE_UNIT*units, BASE_UNIT];
    attachable(anchor=anchor, spin=spin, orient=orient, size=support_dimensions) {
        difference() {

            color(debug_colors ? HR_YELLOW : HR_CORE_SUPPORT_PRIMARY_COLOR)
            cuboid(support_dimensions, chamfer=disable_chamfer ? 0 : BASE_CHAMFER);

            ycopies(spacing=BASE_UNIT, n=units) {

                color(debug_colors ? HR_RED : HR_CORE_SUPPORT_PRIMARY_COLOR) lockpin_hole_support();
            }
            if (x_holes) {
                ycopies(spacing=BASE_UNIT, n=units) {

                    color(debug_colors ? HR_RED : HR_CORE_SUPPORT_PRIMARY_COLOR) rotate([0,90,0]) lockpin_hole_support();
                }
            }
        }
        children();
    }
}
module lockpin_hole_support() {
    lock_pin_center_side = LOCKPIN_HOLE_SIDE_LENGTH + PRINTING_LAYER_WIDTH*2;
    lock_pin_center_dimension = [lock_pin_center_side, lock_pin_center_side];

    lock_pin_outer_side = LOCKPIN_HOLE_SIDE_LENGTH + LOCKPIN_HOLE_CHAMFER*2;
    lock_pin_outer_dimension = [lock_pin_outer_side, lock_pin_outer_side];

    lock_pin_prismoid_inner_length = BASE_UNIT/2 - LOCKPIN_HOLE_CHAMFER;
    lock_pin_prismoid_outer_length = LOCKPIN_HOLE_CHAMFER;

    module hole_half() {
        union() {
            prismoid(size1=lock_pin_center_dimension, size2=LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION, h=lock_pin_prismoid_inner_length);
            translate([0, 0, lock_pin_prismoid_inner_length]) {
                prismoid(size1=LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION, size2=lock_pin_outer_dimension, h=lock_pin_prismoid_outer_length);
            }
        }
    }

    hole_half();

    mirror([0, 0, 1]) {
        hole_half();
    }
}

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

lockpin_chamfer = PRINTING_LAYER_WIDTH;
lockpin_width_outer = LOCKPIN_HOLE_SIDE_LENGTH;
lockpin_width_inner = LOCKPIN_HOLE_SIDE_LENGTH + PRINTING_LAYER_WIDTH * 2;
lockpin_height = lockpin_width_outer - TOLERANCE;
lockpin_prismoid_length = (BASE_UNIT - BASE_STRENGTH) / 2;
lockpin_endpart_length = BASE_STRENGTH + BASE_STRENGTH / 2 + TOLERANCE;
grip_width = lockpin_width_outer + BASE_STRENGTH*2;
grip_thickness_inner = PRINTING_LAYER_WIDTH*2;
grip_thickness_outer = BASE_STRENGTH / 2;
grip_distance = BASE_STRENGTH / 2;
grip_base_length = grip_thickness_inner + grip_thickness_outer + grip_distance + lockpin_chamfer + TOLERANCE/2;
module lockpin(grip_type = LP_GRIP_STANDARD, neck_extension = LP_NECK_EXT_NONE) {
  rotate([90,0,0])
  difference() {

    union() {

      color(HR_YELLOW)
      tension_shape();

      end_parts(grip_type, neck_extension);

      color(HR_BLUE)
      neck(neck_extension, grip_type);

      color(HR_GREEN)
      grip(grip_type, neck_extension);
    }

    color(HR_RED)
    tension_hole();
  }
}
module grip(grip_type = LP_GRIP_STANDARD, neck_extension = LP_NECK_EXT_NONE) {
  if (grip_type != LP_GRIP_NO_GRIP) {
    has_neck_ext = neck_extension == LP_NECK_EXT_NECK || neck_extension == LP_NECK_EXT_BOTH;
    grip_side_extension = has_neck_ext ? LP_NECK_EXTENSION_UNIT : 0;
    grip_base_dimensions = [lockpin_width_outer, lockpin_height, grip_base_length];
    grip_outer_dimensions = [grip_type == LP_GRIP_EXTENDED ? grip_width * 1.5 : grip_width, lockpin_height, grip_thickness_outer];
    grip_inner_dimensions = [grip_width, lockpin_height, grip_thickness_inner];

    base_translation = lockpin_prismoid_length + lockpin_endpart_length - lockpin_chamfer - TOLERANCE/2 + grip_side_extension;

    union() {

      translate([0, 0, -base_translation - grip_base_length / 2])
        cuboid(grip_base_dimensions, chamfer=lockpin_chamfer, except=TOP);

      if(grip_type == LP_GRIP_STANDARD || grip_type == LP_GRIP_EXTENDED) {
        translate([0, 0, -base_translation - grip_base_length + grip_thickness_outer / 2])
          cuboid(grip_outer_dimensions, chamfer=lockpin_chamfer, edges=BOTTOM);

        translate([0, 0, -base_translation - grip_base_length + grip_thickness_outer + grip_thickness_inner / 2 + grip_distance])
          cuboid(grip_inner_dimensions, chamfer=lockpin_chamfer, edges=BOTTOM);
      }
    }
  }
}
module neck(neck_extension = LP_NECK_EXT_NONE, grip_type = LP_GRIP_STANDARD) {
  lockpin_fillet = lockpin_width_outer / 3;
  neck_dimensions = [lockpin_width_outer, lockpin_height, LP_NECK_EXTENSION_UNIT];
  neck_z = lockpin_prismoid_length + lockpin_endpart_length - TOLERANCE/2 + LP_NECK_EXTENSION_UNIT / 2;
  has_neck_ext = neck_extension == LP_NECK_EXT_NECK || neck_extension == LP_NECK_EXT_BOTH;
  has_tail_neck = neck_extension == LP_NECK_EXT_TAIL || neck_extension == LP_NECK_EXT_BOTH;

  if (has_neck_ext) {
    translate([0, 0, -neck_z])
    if (grip_type != LP_GRIP_NO_GRIP) {

      cuboid(neck_dimensions, chamfer=lockpin_chamfer, except=[TOP, BOTTOM]);
    } else {

      intersection() {
        cuboid(neck_dimensions, rounding=lockpin_fillet, edges=[BOTTOM + LEFT, BOTTOM + RIGHT]);
        cuboid(neck_dimensions, chamfer=lockpin_chamfer, edges=[FRONT, BACK], except=TOP);
      }
    }
  }

  if (has_tail_neck) {
    translate([0, 0, neck_z])

    intersection() {
      cuboid(neck_dimensions, rounding=lockpin_fillet, edges=[TOP + LEFT, TOP + RIGHT]);
      cuboid(neck_dimensions, chamfer=lockpin_chamfer, edges=[FRONT, BACK], except=BOTTOM);
    }
  }
}
module end_parts(grip_type = LP_GRIP_STANDARD, neck_extension = LP_NECK_EXT_NONE) {
  has_neck_ext = neck_extension == LP_NECK_EXT_NECK || neck_extension == LP_NECK_EXT_BOTH;
  has_tail_neck = neck_extension == LP_NECK_EXT_TAIL || neck_extension == LP_NECK_EXT_BOTH;
  end_part_half(true, has_tail_neck);
  mirror([0, 0, 1]) end_part_half(grip_type == LP_GRIP_NO_GRIP && neck_extension == LP_NECK_EXT_NONE, has_neck_ext);
}
module end_part_half(front = false, has_neck = false) {

  lockpin_fillet_front = lockpin_width_outer / 3;
  lockpin_endpart_dimension = [lockpin_width_outer, lockpin_height, lockpin_endpart_length];

  translate([0, 0, lockpin_prismoid_length + lockpin_endpart_length / 2 - TOLERANCE/2])
  color(HR_BLUE)

  intersection() {
    cuboid(lockpin_endpart_dimension, rounding=front && !has_neck ? lockpin_fillet_front : 0, edges=[TOP + LEFT, TOP + RIGHT]);
    cuboid(lockpin_endpart_dimension, chamfer=lockpin_chamfer, edges=[FRONT,BACK], except=has_neck ? [BOTTOM, TOP] : BOTTOM);
  }
}
module tension_shape() {
    tension_shape_half();
    mirror([0, 0, 1]) tension_shape_half();
}
module tension_shape_half() {
  lockpin_inner_dimension = [lockpin_width_inner, lockpin_height];
  lockpin_outer_dimension = [lockpin_width_outer, lockpin_height];
  lockpin_fillet_sides = BASE_UNIT;

  prismoid(lockpin_inner_dimension, lockpin_outer_dimension, height=lockpin_prismoid_length, chamfer=lockpin_chamfer);
}
module tension_hole(){
  tension_hole_half();
  mirror([0,0,1]) tension_hole_half();
}
module tension_hole_half(){
  lockpin_tension_angle = 86.5;
  lockpin_tension_hole_width_inner = PRINTING_LAYER_WIDTH * 4;
  lockpin_tension_hole_height = BASE_UNIT / 2;
  lockpin_tension_hole_inner_dimension = [lockpin_tension_hole_width_inner, lockpin_height];
  prismoid(size1=lockpin_tension_hole_inner_dimension, height=lockpin_tension_hole_height, xang=lockpin_tension_angle, yang=90);
}
$fn = 100;

// Color based on configuration:
// HR_GREEN - standard (no pull through)
// HR_YELLOW - pull-through (x/y/z pull through)

function get_connector_color(pull_through_axis="none") =
  pull_through_axis != "none" ? HR_YELLOW :
  HR_GREEN;

color(get_connector_color(pull_through_axis))
connector(dimensions, directions, pull_through_axis, optimal_orientation);
