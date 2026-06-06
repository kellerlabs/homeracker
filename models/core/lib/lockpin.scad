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

HR_CORE_LOCKPIN_PRIMARY_COLOR = HR_YELLOW;

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
 *       - LP_NECK_EXT_NECK (1): Neck-side extension (between body and grip).
 *       - LP_NECK_EXT_BOTH (2): Both sides extended.
 *       - LP_NECK_EXT_TAIL (3): Tail-side neck extension (opposite of grip).
 *
 * Usage:
 *   lockpin();
 *   lockpin(grip_type=LP_GRIP_NO_GRIP);
 *   lockpin(neck_extension=LP_NECK_EXT_NECK);
 */
module lockpin(grip_type = LP_GRIP_STANDARD, neck_extension = LP_NECK_EXT_NONE,
  strength = HR_CORE_LOCKPIN_TENSION_HOLE_STRENGTH_REGULAR,
  debug_colors = false, chamfer_enabled = true
) {
  rotate([90,0,0])
  difference() {
    // Create the lockpin shape
    union() {
      // Mid part (outer shape)
      color_this(debug_colors ? HR_BLUE : HR_CORE_LOCKPIN_PRIMARY_COLOR)
      tension_shape(chamfer_enabled);
      // End part
      color_this(debug_colors ? HR_GREEN : HR_CORE_LOCKPIN_PRIMARY_COLOR)
      end_parts(grip_type, neck_extension, chamfer_enabled);
      // Neck extension
      color_this(debug_colors ? HR_BLUE : HR_CORE_LOCKPIN_PRIMARY_COLOR)
      neck(neck_extension, grip_type, chamfer_enabled);
      // Grip part
      color_this(debug_colors ? HR_YELLOW : HR_CORE_LOCKPIN_PRIMARY_COLOR)
      grip(grip_type, neck_extension, chamfer_enabled);
    }
    // Subtract the tension hole
    color_this(debug_colors ? HR_RED : HR_CORE_LOCKPIN_PRIMARY_COLOR)
    tension_hole(strength);
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
module grip(grip_type = LP_GRIP_STANDARD, neck_extension = LP_NECK_EXT_NONE, chamfer_enabled=true) {
  if (grip_type != LP_GRIP_NO_GRIP) {
    has_neck_ext = neck_extension == LP_NECK_EXT_NECK || neck_extension == LP_NECK_EXT_BOTH;
    grip_side_extension = has_neck_ext ? LP_NECK_EXTENSION_UNIT : 0;
    grip_base_dimensions = [lockpin_width_outer, lockpin_height, grip_base_length];
    grip_outer_dimensions = [grip_type == LP_GRIP_EXTENDED ? grip_width * 1.5 : grip_width, lockpin_height, grip_thickness_outer];
    grip_inner_dimensions = [grip_width, lockpin_height, grip_thickness_inner];

    base_translation = lockpin_prismoid_length + lockpin_endpart_length - lockpin_chamfer - TOLERANCE/2 + grip_side_extension;

    union() {
      // Base part of the grip
      translate([0, 0, -base_translation - grip_base_length / 2])
        cuboid(grip_base_dimensions, chamfer=chamfer_enabled ? lockpin_chamfer : 0, except=TOP);

      if(grip_type == LP_GRIP_STANDARD || grip_type == LP_GRIP_EXTENDED) {
        translate([0, 0, -base_translation - grip_base_length + grip_thickness_outer / 2])
          cuboid(grip_outer_dimensions, chamfer=chamfer_enabled ? lockpin_chamfer : 0, edges=BOTTOM);
        // Inner part of the grip
        translate([0, 0, -base_translation - grip_base_length + grip_thickness_outer + grip_thickness_inner / 2 + grip_distance])
          cuboid(grip_inner_dimensions, chamfer=chamfer_enabled ? lockpin_chamfer : 0, edges=BOTTOM);
      }
    }
  }
}

/**
 * 📐 neck module
 *
 * Creates neck extensions on the lock pin.
 *   LP_NECK_EXT_NECK: neck-side extension only (between body and grip).
 *   LP_NECK_EXT_BOTH: both neck-side and tail-side extensions.
 *   LP_NECK_EXT_TAIL: tail-side extension only (opposite of grip).
 * Each extension adds LP_NECK_EXTENSION_UNIT.
 * Outer ends get chamfer + fillet; connected ends stay flush.
 */
module neck(neck_extension = LP_NECK_EXT_NONE, grip_type = LP_GRIP_STANDARD, chamfer_enabled=true) {
  lockpin_fillet = lockpin_width_outer / 3;
  neck_dimensions = [lockpin_width_outer, lockpin_height, LP_NECK_EXTENSION_UNIT];
  neck_z = lockpin_prismoid_length + lockpin_endpart_length - TOLERANCE/2 + LP_NECK_EXTENSION_UNIT / 2;
  has_neck_ext = neck_extension == LP_NECK_EXT_NECK || neck_extension == LP_NECK_EXT_BOTH;
  has_tail_neck = neck_extension == LP_NECK_EXT_TAIL || neck_extension == LP_NECK_EXT_BOTH;

  // Neck-side extension
  if (has_neck_ext) {
    translate([0, 0, -neck_z])
    if (grip_type != LP_GRIP_NO_GRIP) {
      // Grip base overlaps into neck — no finishing on outer (BOTTOM) end
      cuboid(neck_dimensions, chamfer=chamfer_enabled ? lockpin_chamfer : 0, except=[TOP, BOTTOM]);
    } else {
      // No grip — fillet and chamfer the outer (BOTTOM) end
      intersection() {
        cuboid(neck_dimensions, rounding=lockpin_fillet, edges=[BOTTOM + LEFT, BOTTOM + RIGHT]);
        cuboid(neck_dimensions, chamfer=chamfer_enabled ? lockpin_chamfer : 0, edges=[FRONT, BACK], except=TOP);
      }
    }
  }
  // Tail-side neck extension
  if (has_tail_neck) {
    translate([0, 0, neck_z])
    // Always fillet and chamfer the outer (TOP) end
    intersection() {
      cuboid(neck_dimensions, rounding=lockpin_fillet, edges=[TOP + LEFT, TOP + RIGHT]);
      cuboid(neck_dimensions, chamfer=chamfer_enabled ? lockpin_chamfer : 0, edges=[FRONT, BACK], except=BOTTOM);
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
module end_parts(grip_type = LP_GRIP_STANDARD, neck_extension = LP_NECK_EXT_NONE, chamfer_enabled=true) {
  has_neck_ext = neck_extension == LP_NECK_EXT_NECK || neck_extension == LP_NECK_EXT_BOTH;
  has_tail_neck = neck_extension == LP_NECK_EXT_TAIL || neck_extension == LP_NECK_EXT_BOTH;
  end_part_half(true, has_tail_neck, chamfer_enabled);
  mirror([0, 0, 1]) end_part_half(grip_type == LP_GRIP_NO_GRIP && neck_extension == LP_NECK_EXT_NONE, has_neck_ext, chamfer_enabled);
}

/**
 * 📐 end_part_half module
 *
 * Creates one half of the end part of the lock pin with chamfered and filleted edges.
 * The front half has filleted top edges for better grip, while the back half has chamfered edges.
 * When has_neck is true, the TOP edge is not chamfered/filleted for a flush neck connection.
 */
module end_part_half(front = false, has_neck = false, chamfer_enabled=true) {

  lockpin_fillet_front = lockpin_width_outer / 3;
  lockpin_endpart_dimension = [lockpin_width_outer, lockpin_height, lockpin_endpart_length]; // cubic

  translate([0, 0, lockpin_prismoid_length + lockpin_endpart_length / 2 - TOLERANCE/2])
  // Since it's not possible to have both chamfer and fillet on the same edges,
  // we use an intersection of two shapes to achieve the desired effect.
  intersection() {
    cuboid(lockpin_endpart_dimension, rounding=front && !has_neck ? lockpin_fillet_front : 0, edges=[TOP + LEFT, TOP + RIGHT]);
    cuboid(lockpin_endpart_dimension, chamfer=chamfer_enabled ? lockpin_chamfer : 0, edges=[FRONT,BACK], except=has_neck ? [BOTTOM, TOP] : BOTTOM);
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
module tension_shape(chamfer_enabled=true) {
    tension_shape_half(chamfer_enabled);
    mirror([0, 0, 1]) tension_shape_half(chamfer_enabled);
}

/**
 * 📐 tension_shape_half module
 *
 * Creates one half of the main body of the lock pin with chamfered prismoid shape.
 */
module tension_shape_half(chamfer_enabled=true) {
  lockpin_inner_dimension = [lockpin_width_inner, lockpin_height]; // planar
  lockpin_outer_dimension = [lockpin_width_outer, lockpin_height]; // planar
  lockpin_fillet_sides = BASE_UNIT;

  prismoid(lockpin_inner_dimension, lockpin_outer_dimension, height=lockpin_prismoid_length, chamfer=(chamfer_enabled ? lockpin_chamfer : 0));
}


/**
 * 📐 tension_hole module
 *
 * Creates the bidirectional chamfered tension hole for lock pins.
 */
module tension_hole(tension_hole_strength_multiplier=HR_CORE_LOCKPIN_TENSION_HOLE_STRENGTH_REGULAR){
  tension_hole_half(tension_hole_strength_multiplier);
  mirror([0,0,1]) tension_hole_half(tension_hole_strength_multiplier);
}

/**
 * 📐 tension_hole_half module
 *
 * Creates one half of the bidirectional chamfered tension hole for lock pins.
 */
HR_CORE_LOCKPIN_TENSION_HOLE_STRENGTH_REGULAR = 4;
HR_CORE_LOCKPIN_TENSION_HOLE_STRENGTH_SLIM = 6;
module tension_hole_half(tension_hole_strength_multiplier=HR_CORE_LOCKPIN_TENSION_HOLE_STRENGTH_REGULAR) {
  lockpin_tension_angle = 86.5; // in degrees
  lockpin_tension_hole_width_inner = PRINTING_LAYER_WIDTH * tension_hole_strength_multiplier; // widest/middle point of the tension hole
  lockpin_tension_hole_height = BASE_UNIT / 2;
  lockpin_tension_hole_inner_dimension = [lockpin_tension_hole_width_inner, lockpin_height+HR_EPSILON]; // planar
  prismoid(size1=lockpin_tension_hole_inner_dimension, height=lockpin_tension_hole_height, xang=lockpin_tension_angle, yang=90);
}

/**
 * 📐 lockpin_hole module
 *
 * Reusable lockpin through-hole for any HomeRacker component.
 * Uses 2-cuboid chamfer approach (main hole + chamfer pyramids at entry faces).
 * Hole extends along Z-axis. Rotate for other orientations.
 *
 * @param depth Hole depth along Z-axis (required)
 * @param chamfer_top Chamfer the +Z (top) face entry (default: true)
 * @param chamfer_bottom Chamfer the -Z (bottom) face entry (default: true)
 * @param anchor BOSL2 anchor point
 * @param spin BOSL2 spin rotation
 * @param orient BOSL2 orientation vector
 */
module lockpin_hole(depth, chamfer_top=true, chamfer_bottom=true,
    anchor=CENTER, spin=0, orient=UP) {
    hole_dims = [LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, depth];
    chamfer_face_dims = [LOCKPIN_HOLE_SIDE_LENGTH + LOCKPIN_HOLE_CHAMFER*2, LOCKPIN_HOLE_SIDE_LENGTH + LOCKPIN_HOLE_CHAMFER*2, LOCKPIN_HOLE_CHAMFER];
    attachable(anchor=anchor, spin=spin, orient=orient, size=hole_dims) {
        cuboid(hole_dims) {
            if (chamfer_top)
                align(TOP, inside=true)
                cuboid(chamfer_face_dims, chamfer=LOCKPIN_HOLE_CHAMFER, edges=BOTTOM);
            if (chamfer_bottom)
                align(BOTTOM, inside=true)
                cuboid(chamfer_face_dims, chamfer=LOCKPIN_HOLE_CHAMFER, edges=TOP);
        }
        children();
    }
}
