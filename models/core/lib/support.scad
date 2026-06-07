// HomeRacker - Core Support
//
// This model is part of the HomeRacker - Core system.
//
// MIT License
// Copyright (c) Patrick Pötz
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

HR_CORE_SUPPORT_PRIMARY_COLOR = HR_CHARCOAL;
HR_CORE_SUPPORT_SECONDARY_COLOR = HR_YELLOW;

/**
 * HomeRacker Support Module
 *
 * Parameters:
 *   units (int, default=3): Number of base units (length) for the support.
 *       - Each unit is 15mm in length along the Y-axis (see base_unit).
 *       - Support height (Z-axis) is always 15mm. Typical range: 1 to 50.
 *   x_holes (bool, default=false): If true, adds horizontal holes along the X-axis.
 *
 * Produces:
 *   A support block for the HomeRacker modular rack system.
 *   The block is sized [15mm x (units*15mm) x 15mm] and includes lock pin holes
 *   for each unit of length, allowing secure connection with other components.
 *
 * Usage:
 *   Call support(units) to generate a support of desired length.
 *   Example: support(units=5, x_holes=true);
 */
module support(units=3, x_holes=false,
    debug_colors=false, disable_chamfer=false,
    anchor=CENTER, spin=0, orient=UP) {

    support_dimensions = [BASE_UNIT, BASE_UNIT*units, BASE_UNIT]; // support dimensions (multi-unit)
    attachable(anchor=anchor, spin=spin, orient=orient, size=support_dimensions) {
        difference() {
            // Single support block
            color(debug_colors ? HR_YELLOW : HR_CORE_SUPPORT_PRIMARY_COLOR)
            cuboid(support_dimensions, chamfer=disable_chamfer ? 0 : BASE_CHAMFER);

            // Create a lock pin hole for each unit of length
            ycopies(spacing=BASE_UNIT, n=units) {
                // the color is for testing purposes only when someone wants to visualize the hole
                color(debug_colors ? HR_RED : HR_CORE_SUPPORT_PRIMARY_COLOR) lockpin_hole_support();
            }
            if (x_holes) {
                ycopies(spacing=BASE_UNIT, n=units) {
                    // the color is for testing purposes only when someone wants to visualize the hole
                    color(debug_colors ? HR_RED : HR_CORE_SUPPORT_PRIMARY_COLOR) rotate([0,90,0]) lockpin_hole_support();
                }
            }
        }
        children();
    }
}

/**
 * 📐 lockpin_hole_support
 *
 * BOSL2 attachable. Creates a bidirectional chamfered hole for lock pins, used in HomeRacker
 * supports and any module that needs a standard lock-pin socket (e.g. split connectors).
 *
 * The geometry is two mirrored halves composed via BOSL2 `attach()`. Each half consists of
 * an inner prismoid (wide → standard) joined to an outer prismoid (standard → chamfer flare).
 * When chamfer is disabled the outer prismoid collapses to the same size as the inner top,
 * producing a flat-ended hole — useful for stacking lockpin holes in advanced assemblies.
 *
 * Parameters:
 *   disable_chamfer (bool, default=false): When false (default), the outer prismoid adds a
 *       chamfer flare for easy pin insertion. When true, the outer prismoid becomes a straight
 *       cuboid — no flare — enabling clean hole-stacking without unwanted edge geometry.
 *   debug_colors (bool, default=false): Colors each prismoid distinctly (green/red) for
 *       visual geometry inspection. Has no effect in production renders.
 *
 * Supports BOSL2 anchor/spin/orient for positional control.
 *
 * Usage:
 *   lockpin_hole_support();                          // standard chamfered hole
 *   lockpin_hole_support(disable_chamfer=true);      // flat-ended hole for stacking
 *   lockpin_hole_support() show_anchors();           // inspect attach points
 */
module lockpin_hole_support(
  disable_chamfer=false, debug_colors=false) {
  lock_pin_center_side = LOCKPIN_HOLE_SIDE_LENGTH + PRINTING_LAYER_WIDTH*2;
  lock_pin_center_dimension = [lock_pin_center_side, lock_pin_center_side];

  lock_pin_outer_side = LOCKPIN_HOLE_SIDE_LENGTH + (disable_chamfer ? 0 : LOCKPIN_HOLE_CHAMFER*2);
  lock_pin_outer_dimension = [lock_pin_outer_side, lock_pin_outer_side];

  lock_pin_prismoid_inner_length = BASE_UNIT/2 - LOCKPIN_HOLE_CHAMFER;
  lock_pin_prismoid_outer_length = LOCKPIN_HOLE_CHAMFER;

  attachable_side_length = disable_chamfer ? lock_pin_center_side : lock_pin_outer_side;
  attachable_height_half = lock_pin_prismoid_inner_length + lock_pin_prismoid_outer_length;

  // Define one half of the hole shape in a module
  module hole_half(anchor=CENTER, spin=0, orient=UP) {
    attachable(anchor=anchor, spin=spin, orient=orient, size=[attachable_side_length, attachable_side_length, attachable_height_half]) {
      down(attachable_height_half/2)
      color_this(debug_colors ? HR_GREEN : HR_CORE_SUPPORT_SECONDARY_COLOR)
      prismoid(size1=lock_pin_center_dimension, size2=LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION, h=lock_pin_prismoid_inner_length){
        attach(TOP,BOTTOM) color_this(debug_colors ? HR_RED : HR_CORE_SUPPORT_SECONDARY_COLOR)
        prismoid(size1=LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION, size2=lock_pin_outer_dimension, h=lock_pin_prismoid_outer_length);
      }
      children();
    }
  }

  // Render the original half
  attachable(anchor=CENTER, spin=0, orient=UP, size=[attachable_side_length, attachable_side_length, attachable_height_half*2]) {
    up(attachable_height_half/2)
    hole_half() {
      attach(BOTTOM,BOTTOM) hole_half();
    }
    children();
  }
}
