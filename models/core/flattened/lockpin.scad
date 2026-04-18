include <BOSL2/std.scad>

/* [Parameters] */

// Type of grip for the lock pin
grip_type = 0; // [0:Standard, 1:Extended, 2:No Grip]

// Neck extension mode
neck_extension = 0; // [0:None, 1:Neck Side, 2:Both Sides, 3:Tail Side]

/* [Hidden] */
// --- from constants.scad ---
TOLERANCE = 0.2;
PRINTING_LAYER_WIDTH = 0.4;
BASE_UNIT = 15;
BASE_STRENGTH = 2;
LOCKPIN_HOLE_SIDE_LENGTH = 4;
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
// --- from lockpin.scad ---
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
$fn = 100;

// --- Examples ---

// Example 1: Create a default lock pin (uses default grip_type)
// lockpin();

// Example 2: Create a lock pin with no grip
// lockpin(grip_type=LP_GRIP_NO_GRIP);

// Example 3: Create a lock pin with neck extension for panel mounting
// lockpin(neck_extension=LP_NECK_EXT_NECK);

// Example 4: Create a lock pin with grip_type and neck_extension as set above
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

color(HR_YELLOW)
lockpin(grip_type=grip_type, neck_extension=neck_extension);
