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
 *   grip_type (string, default="standard"): Type of grip for the lock pin.
 *       - "standard": Two grip arms on both sides.
 *       - "extended": Standard grip with an extended outer arm for improved stability.
 *       - "no_grip": No grip arms.
 *
 * Produces:
 *   A lock pin with a bidirectional tension hole and optional grip arms.
 *
 * Usage:
 *   Call lockpin(grip_type) to generate a lock pin of desired grip type.
 *   Example: lockpin(grip_type="no_grip");
 */
module lockpin(grip_type = "standard") {
  rotate([90,0,0])
  difference() {
    // Create the lockpin shape
    union() {
      // Mid part (outer shape)
      color(HR_YELLOW)
      tension_shape();
      // End part
      end_parts(grip_type);
      // Grip part
      color(HR_GREEN)
      grip(grip_type);
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
 * If grip_type is "no_grip", no grip arms are created.
 * If grip_type is "standard", a symmetric two-stage grip is created.
 * If grip_type is "extended", standard grip with an extended outer arm for improved stability.
 * If grip_type is "z_grip", a Z-shaped grip variant is created (not implemented yet).
 */
module grip(grip_type = "standard") {
  if (grip_type != "no_grip") {
    grip_base_dimensions = [lockpin_width_outer, lockpin_height, grip_base_length];
    grip_outer_dimensions = [grip_type == "extended"?grip_width * 1.5:grip_width, lockpin_height, grip_thickness_outer];
    grip_inner_dimensions = [grip_width, lockpin_height, grip_thickness_inner];

    base_translation = lockpin_prismoid_length + lockpin_endpart_length - lockpin_chamfer - TOLERANCE/2;

    union() {
      // Base part of the grip
      translate([0, 0, -base_translation - grip_base_length / 2])
        cuboid(grip_base_dimensions, chamfer=lockpin_chamfer, except=TOP);

      if(grip_type == "standard" || grip_type == "extended") {
        translate([0, 0, -base_translation - grip_base_length + grip_thickness_outer / 2])
          cuboid(grip_outer_dimensions, chamfer=lockpin_chamfer, except=TOP);
        // Inner part of the grip
        translate([0, 0, -base_translation - grip_base_length + grip_thickness_outer + grip_thickness_inner / 2 + grip_distance])
          cuboid(grip_inner_dimensions, chamfer=lockpin_chamfer, except=TOP);
      } else if (grip_type == "z_grip") {
        // TODO: Z-Grip variant has only 1 arm on each side but each arm is thicker
        echo("Z-Grip variant not implemented yet.");
      }
    }
  }
}

/**
 * 📐 end_parts module
 *
 * Creates the complete end part of the lock pin with chamfered and filleted edges.
 * The front half has filleted top edges for better grip, while the back half has chamfered edges.
 * If grip_type is "no_grip", both halves will have chamfered edges.
 */
module end_parts(grip_type = "standard") {
  end_part_half(true);
  mirror([0, 0, 1]) end_part_half(grip_type == "no_grip");
}

/**
 * 📐 end_part_half module
 *
 * Creates one half of the end part of the lock pin with chamfered and filleted edges.
 * The front half has filleted top edges for better grip, while the back half has chamfered edges.
 */
module end_part_half(front = false) {

  lockpin_fillet_front = lockpin_width_outer / 3;
  lockpin_endpart_dimension = [lockpin_width_outer, lockpin_height, lockpin_endpart_length]; // cubic

  translate([0, 0, lockpin_prismoid_length + lockpin_endpart_length / 2 - TOLERANCE/2])
  color(HR_BLUE)
  // Since it's not possible to have both chamfer and fillet on the same edges,
  // we use an intersection of two shapes to achieve the desired effect.
  intersection() {
    cuboid(lockpin_endpart_dimension, rounding=front ? lockpin_fillet_front : 0, edges=[TOP + LEFT, TOP + RIGHT]);
    cuboid(lockpin_endpart_dimension, chamfer=lockpin_chamfer, edges=[FRONT,BACK], except=BOTTOM);
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
