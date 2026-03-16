// HomeRacker - Core Support
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
module support(units=3, x_holes=false) {
    support_dimensions = [BASE_UNIT, BASE_UNIT*units, BASE_UNIT]; // support dimensions (multi-unit)

    difference() {
        // Single support block
        color("darkslategray")
        cuboid(support_dimensions, chamfer=BASE_CHAMFER);

        // Create a lock pin hole for each unit of length
        ycopies(spacing=BASE_UNIT, n=units) {
            // the color is for testing purposes only when someone wants to visualize the hole
            color("red") lock_pin_hole();
        }
        if (x_holes) {
            ycopies(spacing=BASE_UNIT, n=units) {
                // the color is for testing purposes only when someone wants to visualize the hole
                color("red") rotate([0,90,0]) lock_pin_hole();
            }
        }
    }
}

/**
 * 📐 lock_pin_hole module
 *
 * Creates a bidirectional chamfered hole for lock pins, used in HomeRacker connectors and supports.
 * The geometry consists of two mirrored prismoids forming a square hole with chamfered edges on both sides,
 * allowing for easy insertion and secure locking of 4mm square lock pins.
 * This ensures printability and mechanical strength while maintaining standard HomeRacker tolerances.
 */
module lock_pin_hole() {
    lock_pin_center_side = LOCKPIN_HOLE_SIDE_LENGTH + PRINTING_LAYER_WIDTH*2;
    lock_pin_center_dimension = [lock_pin_center_side, lock_pin_center_side];

    lock_pin_outer_side = LOCKPIN_HOLE_SIDE_LENGTH + LOCKPIN_HOLE_CHAMFER*2;
    lock_pin_outer_dimension = [lock_pin_outer_side, lock_pin_outer_side];

    lock_pin_prismoid_inner_length = BASE_UNIT/2 - LOCKPIN_HOLE_CHAMFER;
    lock_pin_prismoid_outer_length = LOCKPIN_HOLE_CHAMFER;

    // Define one half of the hole shape in a module
    module hole_half() {
        union() {
            prismoid(size1=lock_pin_center_dimension, size2=LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION, h=lock_pin_prismoid_inner_length);
            translate([0, 0, lock_pin_prismoid_inner_length]) {
                prismoid(size1=LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION, size2=lock_pin_outer_dimension, h=lock_pin_prismoid_outer_length + EPSILON);
            }
        }
    }

    // Render the original half
    hole_half();

    // Render the mirrored half to complete the shape
    mirror([0, 0, 1]) {
        hole_half();
    }
}
