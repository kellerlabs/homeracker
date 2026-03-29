// HomeRacker - Support Grid
//
// This file is part of HomeRacker implementation by KellerLab.
// It contains the support grid module
// to create HomeRacker-compatible grids to store HomeRacker supports.
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
include <supportbin.scad>
include <../../core/lib/constants.scad>

/* [Hidden] */
HR_SG_PRIMARY_COLOR = HR_YELLOW;

HR_SG_MOUNTING_AXIS_VERTICAL = 1;
HR_SG_MOUNTING_AXIS_HORIZONTAL = 2;
HR_SG_MOUNTING_AXIS_BOTH = 3;

/**
 * Mounting ear that clips the support grid onto a HomeRacker frame.
 * Consists of a base plate with a lock-pin hole and a hook that wraps around the frame rail.
 *
 * @param grid_depth Grid depth in HomeRacker units (determines ear depth)
 * @param debug_colors Enable color-coding for visual debugging
 * @param disable_chamfer Disable chamfers for easier measurement
 */
module mount_ear(grid_depth, debug_colors=false, anchor=CENTER, spin=0, orient=UP, disable_chamfer=false) {

  attachable_width = BASE_UNIT;
  attachable_height = BASE_UNIT + BASE_STRENGTH;
  attachable_depth = grid_depth * BASE_UNIT;
  attachable(anchor=anchor, spin=spin, orient=orient, size=[attachable_width, attachable_depth, attachable_height]){
    down(BASE_UNIT/2)
    color(debug_colors ? HR_WHITE : HR_SG_PRIMARY_COLOR)
    diff()
    cuboid([attachable_width, attachable_depth, BASE_STRENGTH], chamfer=disable_chamfer ? 0 : BASE_CHAMFER, edges=BOTTOM, except=RIGHT){
      attach(TOP, BOTTOM) cuboid([attachable_width, attachable_depth, BASE_UNIT],chamfer=BASE_UNIT,edges=TOP+LEFT){
        align(CENTER) tag("remove") cuboid([attachable_width, attachable_depth - 2*BASE_STRENGTH, BASE_UNIT]);
      }
      align(CENTER) tag("remove") cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, BASE_STRENGTH], chamfer=-LOCKPIN_HOLE_CHAMFER, edges=TOP);
    }
    children();
  }
}

/**
 * Outer frame shell for the support grid. Holds the pocket grid and provides
 * attachment points for mounting ears. Optionally includes a bottom end piece
 * as a backstop.
 *
 * @param frame_x Frame width in mm
 * @param frame_y Frame height in mm
 * @param grid_x Inner pocket grid width in mm
 * @param grid_y Inner pocket grid height in mm
 * @param height Frame depth in mm
 * @param end_piece If true, add a thin bottom plate as a backstop
 * @param mounting_axis Where to place ears: VERTICAL (sides), HORIZONTAL (top/bottom), or BOTH
 * @param disable_chamfer Disable chamfers for easier measurement
 */
module supportgrid_frame(frame_x, frame_y, grid_x, grid_y, height, end_piece,
  mounting_axis=HR_SG_MOUNTING_AXIS_VERTICAL,
  debug_colors=false, anchor=CENTER, spin=0, orient=UP, disable_chamfer=false) {

  chamfer_subract = (BASE_UNIT+BASE_STRENGTH) * 2;
  chamfer_subtract_horizontal = mounting_axis != HR_SG_MOUNTING_AXIS_VERTICAL ? chamfer_subract : 0;
  chamfer_subtract_vertical = mounting_axis != HR_SG_MOUNTING_AXIS_HORIZONTAL ? chamfer_subract : 0;
  chamfer_color = debug_colors ? HR_RED : HR_SG_PRIMARY_COLOR;
  chamfer_strength = disable_chamfer ? 0 : BASE_CHAMFER;

  attachable(anchor=anchor, spin=spin, orient=orient, size=[frame_x, frame_y, height]){
    color_this(debug_colors ? HR_BLUE : HR_SG_PRIMARY_COLOR)
    diff()
    cuboid([frame_x, frame_y, height]){
      tag("remove") cuboid([grid_x, grid_y, height + HR_SB_EPSILON]);
      if(end_piece) tag("keep") color_this(debug_colors ? HR_YELLOW : HR_SG_PRIMARY_COLOR) align(BOTTOM,inside=true) cuboid([grid_x, grid_y, BASE_STRENGTH/2]);
      color_this(chamfer_color) edge_mask([FRONT,BACK],except=[LEFT,RIGHT]) chamfer_edge_mask(l=frame_x - chamfer_subtract_horizontal, chamfer=chamfer_strength);
      color_this(chamfer_color) edge_mask([LEFT,RIGHT],except=[FRONT,BACK]) chamfer_edge_mask(l=frame_y - chamfer_subtract_vertical, chamfer=chamfer_strength);
    }
    children();
  }
}

/**
 * Complete support grid: a frame-mounted pocket grid for organizing HomeRacker
 * supports directly within a rack. Sized to fit a given HomeRacker frame opening
 * and attaches via mounting ears with lock pins.
 *
 * @param hr_width Frame width in HomeRacker units (1 unit = 15mm)
 * @param hr_height Frame height in HomeRacker units (1 unit = 15mm)
 * @param end_piece If true, add a backstop to prevent supports sliding through
 * @param funnel_strength Divider wall thickness in mm
 * @param grid_depth Grid depth in HomeRacker units (longer = more stable)
 * @param mounting_axis Ear placement: HR_SG_MOUNTING_AXIS_VERTICAL, _HORIZONTAL, or _BOTH
 * @param disable_chamfer Disable chamfers for easier measurement
 */
module supportgrid(hr_width, hr_height, end_piece,
  funnel_strength=BASE_STRENGTH,
  grid_depth=BASE_UNIT, mounting_axis=HR_SG_MOUNTING_AXIS_VERTICAL,
  debug_colors=false, disable_chamfer=false) {
  supports_x = support_per_hr_unit(hr_width, funnel_strength, BASE_CHAMFER);
  supports_y = support_per_hr_unit(hr_height, funnel_strength, BASE_CHAMFER);

  frame_x = hr_width * BASE_UNIT;
  frame_y = hr_height * BASE_UNIT;
  height = grid_depth * BASE_UNIT;

  spacing = BASE_UNIT + funnel_strength + TOLERANCE;
  grid_x = spacing * supports_x + PRINTING_LAYER_WIDTH;
  grid_y = spacing * supports_y + PRINTING_LAYER_WIDTH;


  supportgrid_frame(frame_x, frame_y, grid_x, grid_y, height, end_piece, mounting_axis=mounting_axis, debug_colors=debug_colors, disable_chamfer=disable_chamfer){
    align(CENTER) full_grid(supports_x=supports_x, supports_y=supports_y, div_strength=funnel_strength,
      height=height, rounding=0, debug_colors=debug_colors);
    if(mounting_axis == HR_SG_MOUNTING_AXIS_VERTICAL || mounting_axis == HR_SG_MOUNTING_AXIS_BOTH){
      align(LEFT,FRONT) mount_ear(grid_depth, debug_colors=debug_colors,spin=0,orient=BACK,disable_chamfer=disable_chamfer);
      align(LEFT,BACK) mount_ear(grid_depth, debug_colors=debug_colors,spin=0,orient=FRONT,disable_chamfer=disable_chamfer);
      mirror([1,0,0]) align(LEFT,FRONT) mount_ear(grid_depth, debug_colors=debug_colors,spin=0,orient=BACK,disable_chamfer=disable_chamfer);
      mirror([1,0,0]) align(LEFT,BACK) mount_ear(grid_depth, debug_colors=debug_colors,spin=0,orient=FRONT,disable_chamfer=disable_chamfer);
    }
    if(mounting_axis == HR_SG_MOUNTING_AXIS_HORIZONTAL || mounting_axis == HR_SG_MOUNTING_AXIS_BOTH){
      align(FRONT,LEFT) mount_ear(grid_depth, debug_colors=debug_colors,spin=90,orient=RIGHT,disable_chamfer=disable_chamfer);
      align(BACK,LEFT) mount_ear(grid_depth, debug_colors=debug_colors,spin=270,orient=RIGHT,disable_chamfer=disable_chamfer);
      mirror([1,0,0]) align(FRONT,LEFT) mount_ear(grid_depth, debug_colors=debug_colors,spin=90,orient=RIGHT,disable_chamfer=disable_chamfer);
      mirror([1,0,0]) align(BACK,LEFT) mount_ear(grid_depth, debug_colors=debug_colors,spin=270,orient=RIGHT,disable_chamfer=disable_chamfer);
    }
  }
}
