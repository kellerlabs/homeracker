// HomeRacker - Support Bin
//
// This file is part of HomeRacker implementation by KellerLab.
// It contains the support bin module to create Gridfinity-compatible bins to store HomeRacker supports.
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

include <../../gridfinity/lib/binbase.scad>
include <../../core/lib/constants.scad>

/* [Parameters] */

// x dimensions (in multiples of 42mm)
grid_x = 2; // [1:1:17]
// y dimensions (in multiples of 42mm)
grid_y = 2; // [1:1:10]

/* [Advanced] */
// thickness of the dividers between cells
divider_strength = 1.2; // [1.0:0.1:3.0]
// grid style: 0 = riser (cross-shaped ridges), 1 = full (solid walls)
grid_style = 0; // [0:Riser, 1:Full]
// height of the pocket grid
height = 15; // [5:1:15]

/* [Hidden] */
// Optimized for 0.4mm nozzle 3D printing (allegedly according to Sonnet 4.5's research)
// Preview: Faster but still smooth
// Render: Based on typical 0.4mm nozzle capabilities
$fs = $preview ? 0.8 : 0.4;
$fa = $preview ? 6 : 2;
HR_SB_EPSILON = 0.01;

HR_GRID_STYLE_RISER = 0;
HR_GRID_STYLE_FULL = 1;

HR_SB_OUTER_WIDTH = BASE_UNIT + divider_strength*2 + TOLERANCE;
HR_SB_DEFAULT_HEIGHT = BASE_UNIT;
HR_SB_TIP_CUT = BASE_STRENGTH/2;

/** * Calculate the difference between the Gridfinity pocket grid length and the actual length occupied by the support units.
 * If positive, there is extra space; if negative, the supports won't fit and you need to subtract 1 support unit.
 *
 * @param units Number of Gridfinity units
 * @return Difference in mm
 */
function get_gridfinity_pocketgrid_diff(gridfinity_units, support_units) =
  let(
    length = GRIDFINITY_BASE_UNIT * gridfinity_units - BINBASE_SUBTRACTOR,
    support_unit = BASE_UNIT + divider_strength + TOLERANCE
  )
  length - (support_units*support_unit+divider_strength);

/** * Calculate the number of support units that fit into the given Gridfinity units.
 *
 * @param gridfinity_units Number of Gridfinity units
 * @return Number of support units that fit
 */
function support_per_gridfinity_unit(units) =
  let(
    length = GRIDFINITY_BASE_UNIT * units - BINBASE_SUBTRACTOR,
    support_unit = BASE_UNIT + divider_strength + TOLERANCE,
    supports_net = floor(length / support_unit)
  )
  (supports_net*support_unit+divider_strength) > length ? supports_net-1 : supports_net;


module cross_riser(height, arm_length, width=divider_strength) {
  chamfer = width/2;
  // X-axis chamfered arm: full height at center, zero at tips
  // Ridge tapers from full width at (height - chamfer) to zero width at top
  hull() {
    cuboid([HR_SB_EPSILON, width, height - chamfer], anchor=BOTTOM);
    cuboid([HR_SB_EPSILON, HR_SB_EPSILON, height], anchor=BOTTOM);
    right(arm_length) cuboid([HR_SB_EPSILON, width, HR_SB_EPSILON], anchor=BOTTOM);
    left(arm_length) cuboid([HR_SB_EPSILON, width, HR_SB_EPSILON], anchor=BOTTOM);
  }
  // Y-axis chamfered arm
  hull() {
    cuboid([width, HR_SB_EPSILON, height - chamfer], anchor=BOTTOM);
    cuboid([HR_SB_EPSILON, HR_SB_EPSILON, height], anchor=BOTTOM);
    back(arm_length) cuboid([width, HR_SB_EPSILON, HR_SB_EPSILON], anchor=BOTTOM);
    fwd(arm_length) cuboid([width, HR_SB_EPSILON, HR_SB_EPSILON], anchor=BOTTOM);
  }
}

module riser_grid(supports_x, supports_y, height=HR_SB_DEFAULT_HEIGHT, rounding=BB_TOP_PART_ROUNDING, anchor=CENTER, spin=0, orient=UP) {
  spacing = HR_SB_OUTER_WIDTH-divider_strength;

  length_x = spacing*supports_x+divider_strength;
  length_y = spacing*supports_y+divider_strength;

  attachable(anchor=CENTER, spin=0, orient=UP, size=[length_x, length_y, height]){
    down(height/2)
    difference() {
      intersection() {
        cuboid([length_x, length_y, height], anchor=BOTTOM, rounding=rounding, except=[BOTTOM,TOP]);
        grid_copies(n=[supports_x+1, supports_y+1], spacing=spacing)
          cross_riser(height, arm_length=height);
      }
      up(height - HR_SB_TIP_CUT) cuboid([length_x+HR_SB_EPSILON, length_y+HR_SB_EPSILON, HR_SB_TIP_CUT+HR_SB_EPSILON], anchor=BOTTOM);
    }
    children();
  }
}

module full_grid(supports_x, supports_y, height=HR_SB_DEFAULT_HEIGHT/2, rounding=BB_TOP_PART_ROUNDING, anchor=CENTER, spin=0, orient=UP) {
  spacing = HR_SB_OUTER_WIDTH-divider_strength;

  length_x = spacing*supports_x+divider_strength;
  length_y = spacing*supports_y+divider_strength;
  attachable(anchor=CENTER, spin=0, orient=UP, size=[length_x, length_y, height]){
    diff()
    cuboid([length_x, length_y, height], rounding=rounding, except=[BOTTOM,TOP])
      tag("remove")
      grid_copies(n=[supports_x, supports_y], spacing=spacing)
        cuboid([BASE_UNIT + TOLERANCE, BASE_UNIT + TOLERANCE, height+HR_SB_EPSILON], chamfer=-divider_strength/2, edges=TOP);
    children();
  }
}

module pocket_grid(supports_x, supports_y, height=HR_SB_DEFAULT_HEIGHT, rounding=BB_TOP_PART_ROUNDING, style=grid_style, anchor=CENTER, spin=0, orient=UP) {
  if (style == HR_GRID_STYLE_RISER)
    riser_grid(supports_x, supports_y, height, rounding, anchor, spin, orient) children();
  else if (style == HR_GRID_STYLE_FULL)
    full_grid(supports_x, supports_y, height, rounding, anchor, spin, orient) children();
}



supports_x = support_per_gridfinity_unit(grid_x);
supports_y = support_per_gridfinity_unit(grid_y);

bigger_rounding_diff = max(get_gridfinity_pocketgrid_diff(grid_x, supports_x), get_gridfinity_pocketgrid_diff(grid_y, supports_y));
rounding_diff = bigger_rounding_diff > BB_TOP_PART_ROUNDING ? BB_TOP_PART_ROUNDING*2 : bigger_rounding_diff;

color_this(HR_BLUE)
binbase_with_topplate(grid_x, grid_y, 1)
attach(TOP,BOTTOM)
color_this(HR_YELLOW)
pocket_grid(supports_x, supports_y, height=height, rounding=BB_TOP_PART_ROUNDING-rounding_diff/2);
