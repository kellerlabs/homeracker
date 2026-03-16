// HomeRacker - Core Lock Pin
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

include <BOSL2/std.scad>
include <constants.scad>

// Lock Pin Dimensions
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
// we add lockpin_chamfer to cover the existing chamfer on the end part
grip_base_length = grip_thickness_inner + grip_thickness_outer + grip_distance + lockpin_chamfer + TOLERANCE/2;

/**
 * 📐 lockpin module
 *
 * Creates a lock pin for the HomeRacker modular rack system.
 *
 * Parameters:
 *   grip_type (number, default=LP_GRIP_STANDARD): Type of grip.
 *       - LP_GRIP_STANDARD (0): Two grip arms on both sides.
 *       - LP_GRIP_EXTENDED (1): Standard grip with an extended outer arm.
 *       - LP_GRIP_NO_GRIP (2): No grip arms.
 *   neck_extension (number, default=LP_NECK_EXT_NONE): Neck extension mode.
 *       - LP_NECK_EXT_NONE (0): No extension (standard lockpin).
 *       - LP_NECK_EXT_GRIP (1): Grip-side neck extension.
 *       - LP_NECK_EXT_BOTH (2): Both sides extended.
 *
 * Usage:
 *   lockpin();
 *   lockpin(grip_type=LP_GRIP_NO_GRIP);
 *   lockpin(neck_extension=LP_NECK_EXT_GRIP);
 */
module lockpin(grip_type = LP_GRIP_STANDARD, neck_extension = LP_NECK_EXT_NONE) {
  rotate([90,0,0])
  difference() {
    // Create the lockpin shape
    union() {
      // Mid part (outer shape)
      color(HR_YELLOW)
      tension_shape();
      // End part
      end_parts(grip_type, neck_extension);
      // Neck extension
      color(HR_BLUE)
      neck(neck_extension, grip_type);
      // Grip part
      color(HR_GREEN)
      grip(grip_type, neck_extension);
    }
    // Subtract the tension hole
    color(HR_RED)
    tension_hole();
  }
}

/**
 * 📐 grip module
 *
 * Creates the grip part of the lock pin.
 * LP_GRIP_NO_GRIP: no grip arms.
 * LP_GRIP_STANDARD: a symmetric two-stage grip.
 * LP_GRIP_EXTENDED: standard grip with an extended outer arm.
 */
module grip(grip_type = LP_GRIP_STANDARD, neck_extension = LP_NECK_EXT_NONE) {
  if (grip_type != LP_GRIP_NO_GRIP) {
    grip_side_extension = neck_extension >= LP_NECK_EXT_GRIP ? LP_NECK_EXTENSION_UNIT : 0;
    grip_base_dimensions = [lockpin_width_outer, lockpin_height, grip_base_length];
    grip_outer_dimensions = [grip_type == LP_GRIP_EXTENDED ? grip_width * 1.5 : grip_width, lockpin_height, grip_thickness_outer];
    grip_inner_dimensions = [grip_width, lockpin_height, grip_thickness_inner];

    base_translation = lockpin_prismoid_length + lockpin_endpart_length - lockpin_chamfer - TOLERANCE/2 + grip_side_extension;

    union() {
      // Base part of the grip
      translate([0, 0, -base_translation - grip_base_length / 2])
        cuboid(grip_base_dimensions, chamfer=lockpin_chamfer, except=TOP);

      if(grip_type == LP_GRIP_STANDARD || grip_type == LP_GRIP_EXTENDED) {
        translate([0, 0, -base_translation - grip_base_length + grip_thickness_outer / 2])
          cuboid(grip_outer_dimensions, chamfer=lockpin_chamfer, edges=BOTTOM);
        // Inner part of the grip
        translate([0, 0, -base_translation - grip_base_length + grip_thickness_outer + grip_thickness_inner / 2 + grip_distance])
          cuboid(grip_inner_dimensions, chamfer=lockpin_chamfer, edges=BOTTOM);
      }
    }
  }
}

/**
 * 📐 neck module
 *
 * Creates neck extensions on the lock pin.
 *   LP_NECK_EXT_GRIP: grip-side extension only.
 *   LP_NECK_EXT_BOTH: both grip-side and front-side extensions.
 * Each extension adds LP_NECK_EXTENSION_UNIT.
 * Outer ends get chamfer + fillet; connected ends stay flush.
 */
module neck(neck_extension = LP_NECK_EXT_NONE, grip_type = LP_GRIP_STANDARD) {
  lockpin_fillet = lockpin_width_outer / 3;
  neck_dimensions = [lockpin_width_outer, lockpin_height, LP_NECK_EXTENSION_UNIT];
  neck_z = lockpin_prismoid_length + lockpin_endpart_length - TOLERANCE/2 + LP_NECK_EXTENSION_UNIT / 2;

  // Grip-side neck extension
  if (neck_extension >= LP_NECK_EXT_GRIP) {
    translate([0, 0, -neck_z])
    if (grip_type != LP_GRIP_NO_GRIP) {
      // Grip base overlaps into neck — no finishing on outer (BOTTOM) end
      cuboid(neck_dimensions, chamfer=lockpin_chamfer, except=[TOP, BOTTOM]);
    } else {
      // No grip — fillet and chamfer the outer (BOTTOM) end
      intersection() {
        cuboid(neck_dimensions, rounding=lockpin_fillet, edges=[BOTTOM + LEFT, BOTTOM + RIGHT]);
        cuboid(neck_dimensions, chamfer=lockpin_chamfer, edges=[FRONT, BACK], except=TOP);
      }
    }
  }
  // Front-side neck extension
  if (neck_extension >= LP_NECK_EXT_BOTH) {
    translate([0, 0, neck_z])
    // Always fillet and chamfer the outer (TOP) end
    intersection() {
      cuboid(neck_dimensions, rounding=lockpin_fillet, edges=[TOP + LEFT, TOP + RIGHT]);
      cuboid(neck_dimensions, chamfer=lockpin_chamfer, edges=[FRONT, BACK], except=BOTTOM);
    }
  }
}

/**
 * 📐 end_parts module
 *
 * Creates the complete end part of the lock pin with chamfered and filleted edges.
 * The front half has filleted top edges for better grip, while the back half has chamfered edges.
 * Fillets are suppressed on ends that connect to a neck extension.
 */
module end_parts(grip_type = LP_GRIP_STANDARD, neck_extension = LP_NECK_EXT_NONE) {
  end_part_half(true, neck_extension >= LP_NECK_EXT_BOTH);
  mirror([0, 0, 1]) end_part_half(grip_type == LP_GRIP_NO_GRIP && neck_extension == LP_NECK_EXT_NONE, neck_extension >= LP_NECK_EXT_GRIP);
}

/**
 * 📐 end_part_half module
 *
 * Creates one half of the end part of the lock pin with chamfered and filleted edges.
 * The front half has filleted top edges for better grip, while the back half has chamfered edges.
 * When has_neck is true, the TOP edge is not chamfered/filleted for a flush neck connection.
 */
module end_part_half(front = false, has_neck = false) {

  lockpin_fillet_front = lockpin_width_outer / 3;
  lockpin_endpart_dimension = [lockpin_width_outer, lockpin_height, lockpin_endpart_length]; // cubic

  translate([0, 0, lockpin_prismoid_length + lockpin_endpart_length / 2 - TOLERANCE/2])
  color(HR_BLUE)
  // Since it's not possible to have both chamfer and fillet on the same edges,
  // we use an intersection of two shapes to achieve the desired effect.
  intersection() {
    cuboid(lockpin_endpart_dimension, rounding=front && !has_neck ? lockpin_fillet_front : 0, edges=[TOP + LEFT, TOP + RIGHT]);
    cuboid(lockpin_endpart_dimension, chamfer=lockpin_chamfer, edges=[FRONT,BACK], except=has_neck ? [BOTTOM, TOP] : BOTTOM);
  }
}

/**
 * 📐 tension_shape module
 *
 * Creates the main body of the lock pin with chamfered prismoid shape.
 * TODO(Challenge): Add fillets to the adjoining edges of both tension_shape_halfs.
 * I haven't found a clean way to do this using BOSL2 yet (only ways that bloat the code significantly).
 * I think it'll work without fillets here for now.
 */
module tension_shape() {
    tension_shape_half();
    mirror([0, 0, 1]) tension_shape_half();
}

/**
 * 📐 tension_shape_half module
 *
 * Creates one half of the main body of the lock pin with chamfered prismoid shape.
 */
module tension_shape_half() {
  lockpin_inner_dimension = [lockpin_width_inner, lockpin_height]; // planar
  lockpin_outer_dimension = [lockpin_width_outer, lockpin_height]; // planar
  lockpin_fillet_sides = BASE_UNIT;

  prismoid(lockpin_inner_dimension, lockpin_outer_dimension, height=lockpin_prismoid_length, chamfer=lockpin_chamfer);
}


/**
 * 📐 tension_hole module
 *
 * Creates the bidirectional chamfered tension hole for lock pins.
 */
module tension_hole(){
  tension_hole_half();
  mirror([0,0,1]) tension_hole_half();
}

/**
 * 📐 tension_hole_half module
 *
 * Creates one half of the bidirectional chamfered tension hole for lock pins.
 */
module tension_hole_half(){
  lockpin_tension_angle = 86.5; // in degrees
  lockpin_tension_hole_width_inner = PRINTING_LAYER_WIDTH * 4; // widest/middle point of the tension hole
  lockpin_tension_hole_height = BASE_UNIT / 2;
  lockpin_tension_hole_inner_dimension = [lockpin_tension_hole_width_inner, lockpin_height + EPSILON ]; // planar
  prismoid(size1=lockpin_tension_hole_inner_dimension, height=lockpin_tension_hole_height, xang=lockpin_tension_angle, yang=90);
}
