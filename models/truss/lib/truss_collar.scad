// HomeRacker - Truss Collar
//
// Open rectangular tube that slides over two narrow (13mm) truss-width supports,
// holding them together as a single structural unit. Lockpin through-holes at
// every unit interval allow the collar to be secured in place.
//
// MIT License
// Copyright (c) 2026 Patrick Pötz
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
include <../../core/lib/constants.scad>
include <../../core/lib/lockpin.scad>

EPSILON = 0.01;

// Truss collar constants
TRUSS_COLLAR_WALL = (2*BASE_UNIT - 2*HR_SUPPORT_WIDTH_TRUSS - TOLERANCE/2) / 2; // 1.95mm
TRUSS_COLLAR_INNER_X = 2 * HR_SUPPORT_WIDTH_TRUSS + TOLERANCE/2; // 26.1mm
TRUSS_COLLAR_INNER_Y = BASE_UNIT + TOLERANCE/2; // 15.1mm
TRUSS_COLLAR_OUTER_X = 2 * BASE_UNIT; // 30mm
TRUSS_COLLAR_OUTER_Y = TRUSS_COLLAR_INNER_Y + 2 * TRUSS_COLLAR_WALL; // 19mm

HR_TRUSS_COLLAR_PRIMARY_COLOR = HR_CHARCOAL;

/**
 * 📐 truss_collar module
 *
 * Creates an open rectangular tube that encloses two 13mm truss-width supports.
 * The collar slides onto the supports from the Z-axis (top) and is secured with
 * lock pins through the Y-axis holes.
 *
 * Lockpin holes are centered at ±BASE_UNIT/2 from collar center (±7.5mm),
 * aligning with each 15mm grid cell center.
 *
 * @param units Length of the collar in base units (min 4 for brick bond)
 * @param debug_colors Show distinct colors per feature for debugging
 * @param disable_chamfer Disable chamfers on lockpin holes
 * @param anchor BOSL2 anchor point
 * @param spin BOSL2 spin rotation
 * @param orient BOSL2 orientation vector
 *
 * Usage:
 *   truss_collar(units=4);
 *   truss_collar(units=6);
 */
module truss_collar(units=4,
    debug_colors=false, disable_chamfer=false,
    anchor=CENTER, spin=0, orient=UP) {

    assert(is_int(units) && units >= 4, "units must be an integer >= 4");

    collar_length = BASE_UNIT * units;
    outer_dims = [TRUSS_COLLAR_OUTER_X, TRUSS_COLLAR_OUTER_Y, collar_length];
    inner_dims = [TRUSS_COLLAR_INNER_X, TRUSS_COLLAR_INNER_Y, collar_length + EPSILON];

    tag_scope("truss_collar")
    attachable(anchor=anchor, spin=spin, orient=orient, size=outer_dims) {
        color_this(debug_colors ? HR_BLUE : HR_TRUSS_COLLAR_PRIMARY_COLOR)
        diff()
        cuboid(outer_dims, chamfer=disable_chamfer ? 0 : BASE_CHAMFER, except=[TOP,BOTTOM]) {
            // Inner cavity (open tube)
            tag("remove") color_this(debug_colors ? HR_GREEN : HR_TRUSS_COLLAR_PRIMARY_COLOR)
            cuboid(inner_dims, chamfer=disable_chamfer ? 0 : -BASE_CHAMFER, edges=[TOP,BOTTOM]);

            // Lockpin through-holes at ±BASE_UNIT/2 from center (grid-aligned)
            zcopies(spacing=BASE_UNIT, n=units) {
                tag("remove") color_this(debug_colors ? HR_RED : HR_TRUSS_COLLAR_PRIMARY_COLOR)
                left(BASE_UNIT/2) rotate([90,0,0]) lockpin_hole(depth=TRUSS_COLLAR_OUTER_Y + EPSILON, chamfer_top=!disable_chamfer, chamfer_bottom=!disable_chamfer);

                tag("remove") color_this(debug_colors ? HR_RED : HR_TRUSS_COLLAR_PRIMARY_COLOR)
                right(BASE_UNIT/2) rotate([90,0,0]) lockpin_hole(depth=TRUSS_COLLAR_OUTER_Y + EPSILON, chamfer_top=!disable_chamfer, chamfer_bottom=!disable_chamfer);
            }
        }
        children();
    }
}
