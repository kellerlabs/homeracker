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


HR_SB_EPSILON = 0.01;

HR_GRID_STYLE_RISER = 0;
HR_GRID_STYLE_FULL = 1;

HR_SB_DEFAULT_HEIGHT = BASE_UNIT;
HR_SB_TIP_CUT = BASE_STRENGTH/2;

HR_SB_PRIMARY_COLOR = HR_YELLOW;

/**
 * Calculate the difference between the Gridfinity pocket grid length and the actual length occupied by the support units.
 * If positive, there is extra space; if negative, the supports won't fit.
 *
 * @param gridfinity_units Number of Gridfinity units (1 unit = 42mm)
 * @param support_units Number of HomeRacker support units to fit
 * @param div_strength Divider wall thickness in mm
 * @return Remaining space in mm (negative = doesn't fit)
 */
function get_gridfinity_pocketgrid_diff(gridfinity_units, support_units, div_strength) =
  let(
    length = GRIDFINITY_BASE_UNIT * gridfinity_units - BINBASE_SUBTRACTOR,
    support_unit = BASE_UNIT + div_strength + TOLERANCE
  )
  length - (support_units*support_unit+div_strength);

/**
 * Calculate the maximum number of HomeRacker support units that fit into the given HomeRacker frame length.
 *
 * @param hr_units Number of HomeRacker units (1 unit = 15mm)
 * @param div_strength Divider wall thickness in mm
 * @param frame_chamfer Optional chamfer size to subtract (x2) from the frame length for better fit (default: 0)
 * @return Number of support units that fit
 */
function support_per_hr_unit(hr_units, div_strength, frame_chamfer=0) =
  let(
    length = BASE_UNIT * hr_units,
    spacing = BASE_UNIT + div_strength + TOLERANCE,
    supports_net = floor((length - PRINTING_LAYER_WIDTH - frame_chamfer*2) / spacing)
  )
  (supports_net*spacing+PRINTING_LAYER_WIDTH) > length ? supports_net-1 : supports_net;

/**
 * Calculate the maximum number of HomeRacker support units that fit into the given Gridfinity grid length.
 *
 * @param units Number of Gridfinity units (1 unit = 42mm)
 * @param div_strength Divider wall thickness in mm
 * @return Number of support units that fit
 */
function support_per_gridfinity_unit(units, div_strength) =
  let(
    length = GRIDFINITY_BASE_UNIT * units - BINBASE_SUBTRACTOR,
    support_unit = BASE_UNIT + div_strength + TOLERANCE,
    supports_net = floor(length / support_unit)
  )
  (supports_net*support_unit+div_strength) > length ? supports_net-1 : supports_net;


/**
 * A single cross-shaped riser element with chamfered arms tapering from full height at center to zero at tips.
 *
 * @param height Total height of the riser
 * @param arm_length Length of each arm from center to tip
 * @param width Thickness of the riser arms
 */
module cross_riser(height, arm_length, width) {
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

/**
 * Grid of cross-shaped risers that hold supports in place via friction.
 * Each cell has a cross riser at its intersection; tips are cut flat for print stability.
 *
 * @param supports_x Number of support cells in X direction
 * @param supports_y Number of support cells in Y direction
 * @param div_strength Divider wall thickness in mm
 * @param height Height of the riser grid
 * @param rounding Corner rounding radius of the outer boundary
 */
module riser_grid(supports_x, supports_y, div_strength, height=HR_SB_DEFAULT_HEIGHT, rounding=BB_TOP_PART_ROUNDING, debug_colors=false, anchor=CENTER, spin=0, orient=UP) {
  spacing = BASE_UNIT + div_strength + TOLERANCE;

  length_x = spacing*supports_x+div_strength;
  length_y = spacing*supports_y+div_strength;

  attachable(anchor=CENTER, spin=0, orient=UP, size=[length_x, length_y, height]){
    color_this(debug_colors ? HR_GREEN : HR_SB_PRIMARY_COLOR)
    down(height/2)
    difference() {
      intersection() {
        cuboid([length_x, length_y, height], anchor=BOTTOM, rounding=rounding, except=[BOTTOM,TOP]);
        grid_copies(n=[supports_x+1, supports_y+1], spacing=spacing)
          cross_riser(height, arm_length=height, width=div_strength);
      }
      up(height - HR_SB_TIP_CUT) cuboid([length_x+HR_SB_EPSILON, length_y+HR_SB_EPSILON, HR_SB_TIP_CUT+HR_SB_EPSILON], anchor=BOTTOM);
    }
    children();
  }
}

/**
 * Grid of solid-walled pockets for holding supports. Each cell is a rectangular cutout with
 * chamfered top edges for easier insertion.
 *
 * @param supports_x Number of support cells in X direction
 * @param supports_y Number of support cells in Y direction
 * @param div_strength Divider wall thickness in mm
 * @param height Height of the pocket walls (default: half of BASE_UNIT)
 * @param rounding Corner rounding radius of the outer boundary
 */
module full_grid(supports_x, supports_y, div_strength,
  height=HR_SB_DEFAULT_HEIGHT/2, rounding=BB_TOP_PART_ROUNDING,
  debug_colors=false, anchor=CENTER, spin=0, orient=UP) {
  spacing = BASE_UNIT + div_strength + TOLERANCE;
  cell = BASE_UNIT + TOLERANCE;
  chamfer = div_strength/2-PRINTING_LAYER_WIDTH;

  length_x = spacing*supports_x+PRINTING_LAYER_WIDTH;
  length_y = spacing*supports_y+PRINTING_LAYER_WIDTH;

  attachable(anchor=CENTER, spin=0, orient=UP, size=[length_x, length_y, height]){
    color(debug_colors ? HR_GREEN : HR_SB_PRIMARY_COLOR)
    diff()
    cuboid([length_x, length_y, height], rounding=rounding, except=[BOTTOM,TOP])
      tag("remove")
      grid_copies(n=[supports_x, supports_y], spacing=spacing) {
        cuboid([cell, cell, height+HR_SB_EPSILON]);
        up((height - chamfer*2)/2)
          prismoid([cell, cell], [cell + chamfer*2, cell + chamfer*2], h=chamfer + HR_SB_EPSILON);
      }
    children();
  }
}

/**
 * Top-level pocket grid that dispatches to riser_grid or full_grid based on style.
 *
 * @param supports_x Number of support cells in X direction
 * @param supports_y Number of support cells in Y direction
 * @param div_strength Divider wall thickness in mm
 * @param height Height of the pocket grid
 * @param rounding Corner rounding radius of the outer boundary
 * @param style Grid style: HR_GRID_STYLE_RISER (cross ridges) or HR_GRID_STYLE_FULL (solid walls)
 */
module pocket_grid(supports_x, supports_y, div_strength, height=HR_SB_DEFAULT_HEIGHT, rounding=BB_TOP_PART_ROUNDING, style=HR_GRID_STYLE_RISER, debug_colors=false, anchor=CENTER, spin=0, orient=UP) {
  if (style == HR_GRID_STYLE_RISER)
    riser_grid(supports_x, supports_y, div_strength, height, rounding, debug_colors, anchor, spin, orient) children();
  else if (style == HR_GRID_STYLE_FULL)
    full_grid(supports_x, supports_y, div_strength, height, rounding, debug_colors, anchor, spin, orient) children();
}

/**
 * Complete support bin: Gridfinity bin base topped with a pocket grid for storing HomeRacker supports.
 *
 * @param grid_x Gridfinity grid units in X direction (1 unit = 42mm)
 * @param grid_y Gridfinity grid units in Y direction (1 unit = 42mm)
 * @param div_strength Divider wall thickness in mm
 * @param height Height of the pocket grid
 * @param style Grid style: HR_GRID_STYLE_RISER (cross ridges) or HR_GRID_STYLE_FULL (solid walls)
 */
module supportbin(grid_x, grid_y, div_strength, height=HR_SB_DEFAULT_HEIGHT, style=HR_GRID_STYLE_RISER, debug_colors=false) {
  supports_x = support_per_gridfinity_unit(grid_x, div_strength);
  supports_y = support_per_gridfinity_unit(grid_y, div_strength);

  bigger_rounding_diff = max(get_gridfinity_pocketgrid_diff(grid_x, supports_x, div_strength), get_gridfinity_pocketgrid_diff(grid_y, supports_y, div_strength));
  rounding_diff = bigger_rounding_diff > BB_TOP_PART_ROUNDING ? BB_TOP_PART_ROUNDING*2 : bigger_rounding_diff;

  color_this(debug_colors ? HR_BLUE : HR_CHARCOAL)
  binbase_with_topplate(grid_x, grid_y, 1)
  attach(TOP,BOTTOM)
  pocket_grid(supports_x, supports_y, div_strength, height=height, rounding=BB_TOP_PART_ROUNDING-rounding_diff/2, style=style, debug_colors=debug_colors);
}
