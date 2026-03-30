// HomeRacker - Racklink
//
// This file is part of HomeRacker implementation by KellerLab.
// It contains the racklink module which can connect independent rack columns together.
// The racklink is basically 2 connected 3-sided sleeves to wrap vertical supports of each rack column.
// Besides connecting the columns for better stability, the racklink also gives a clean look to the front/back of the rack.
// Use case: Creating very big racks affords a lot of planning ahead and is error-prone.
//           The idea is to create small independent rack columns and then connect them together with the racklink.
//           This way, you can easily add more columns later on and don't have to worry about the exact dimensions of the rack at the beginning.
// Downside: You need more material. When before you needed 3 vertical supports for a 2 column rack, you now need 4.
//           This calculation continues for bigger racks. The formula for the material needed is now 2n instead of n+1 (n = number of columns).
//           So for a 4 column rack, you need 8 vertical supports instead of 5.
//           Depending on your budget and the size of the rack, this might be a dealbreaker.
//           But if you want a big rack and don't want to worry about the exact dimensions, the racklink is a great solution.
//
// tl;dr:   Racklink connects rack columns together for better stability and a cleaner look,
//          but requires more material. Great for big racks where dimensions are uncertain.
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

/** Features
* connects rack columns together
* due to its double u-shape, it is easy to mount and gives a clean look to the front/back of the rack
* The cover plate extends 1.5 homeracker units on top/bottom to cover half of the adjoining connector
* Each u-shape can be customized in terms of where to start and end.
  So if your left and right rack column have different heights but at least share one support unit,
  you can still use the racklink to connect them together.
  (per default, both u-shapes start at the bottom and end at the top of the racklink,
  so they are fully covering the vertical supports of the rack columns)
* Due to the described customizability of each individual u-shape, you can connect rack columns of different heights,
  which would not have been possible so easily (if at all) when building a single rack with different column heights from the beginning.
*/

include <BOSL2/std.scad>
include <../../core/lib/constants.scad>

/* [Hidden] */
EPSILON = 0.01;
HR_RL_PRIMARY_COLOR = HR_YELLOW;
SLEEVE_WIDTH = BASE_UNIT + 2*BASE_STRENGTH + TOLERANCE; // to fit around the vertical support of the rack column

module support_sleeve(length, debug_colors=false, disable_chamfer=false, anchor=CENTER, orient=UP, spin=0) {
  assert(is_int(length) && length > 0, "Length must be a positive integer");

  attachable_width = SLEEVE_WIDTH; // to fit around the vertical support of the rack column
  attachable_depth = BASE_UNIT + BASE_STRENGTH + TOLERANCE/2; // to fit around the vertical support of the rack column
  attachable_height = length * BASE_UNIT - TOLERANCE; // height of the sleeve, determined by the input length in HomeRacker units
  lockpin_chamfer = LOCKPIN_HOLE_CHAMFER;
  tag_scope("sleeve")
  attachable(anchor=anchor, orient=orient, spin=spin, size=[attachable_width, attachable_depth, attachable_height]){
    color_this(debug_colors ? HR_GREEN : HR_RL_PRIMARY_COLOR)
    diff()
    cuboid([attachable_width, attachable_depth, attachable_height], chamfer=disable_chamfer ? 0 : BASE_CHAMFER){
      align(BACK, inside=true) tag("remove") color_this(debug_colors ? HR_WHITE : HR_RL_PRIMARY_COLOR) cuboid([BASE_UNIT+TOLERANCE, BASE_UNIT+TOLERANCE/2, attachable_height+EPSILON]);
      zcopies(BASE_UNIT,n=length) tag("remove") back((BASE_STRENGTH+TOLERANCE/2)/2) color(debug_colors ? HR_RED : HR_RL_PRIMARY_COLOR) cuboid([attachable_width+EPSILON, LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH]){
        align(RIGHT, inside=true) cuboid([lockpin_chamfer, LOCKPIN_HOLE_SIDE_LENGTH+lockpin_chamfer*2, LOCKPIN_HOLE_SIDE_LENGTH+lockpin_chamfer*2], chamfer=lockpin_chamfer, edges=LEFT);
        align(LEFT, inside=true) cuboid([lockpin_chamfer, LOCKPIN_HOLE_SIDE_LENGTH+lockpin_chamfer*2, LOCKPIN_HOLE_SIDE_LENGTH+lockpin_chamfer*2], chamfer=lockpin_chamfer, edges=RIGHT);
      }
    }
    children();
  }
}

module cover_plate(length, distance, debug_colors=false, disable_chamfer=false, anchor=CENTER, orient=UP, spin=0) {
  assert(length > 0, "Length must be greater than 0");
  assert(distance > 0, "Distance must be greater than 0");

  attachable_width = distance*BASE_UNIT - BASE_STRENGTH*2 - TOLERANCE; // width of the cover plate, determined by the input distance in HomeRacker units, minus the horizontal offset of the sleeves on both sides to ensure the cover plate fits between the sleeves
  assert(attachable_width > 0, "Distance too small: cover_plate width becomes non-positive. Increase distance.");
  assert(attachable_width > BASE_STRENGTH*2, "Distance too small: cover_plate inner width becomes non-positive. Increase distance.");
  attachable_depth = BASE_STRENGTH*2;
  attachable_height = length * BASE_UNIT + BASE_UNIT*3; // 1.5 HomeRacker units extension on top and bottom to cover half of the adjoining connector, determined by the input length in HomeRacker units
  tag_scope("cover_plate")
  attachable(anchor=anchor, orient=orient, spin=spin, size=[attachable_width, attachable_depth, attachable_height]){
    color_this(debug_colors ? HR_BLUE : HR_RL_PRIMARY_COLOR)
    diff()
    cuboid([attachable_width, attachable_depth, attachable_height], chamfer=disable_chamfer ? 0 : BASE_CHAMFER){
      align(BACK, inside=true) tag("remove") color_this(debug_colors ? HR_WHITE : HR_RL_PRIMARY_COLOR)
        cuboid([attachable_width-BASE_STRENGTH*2, attachable_depth-BASE_STRENGTH, attachable_height-BASE_STRENGTH*2]);
    }
    children();
  }
}

/**
* Calculates the vertical start offset (in mm) for a sleeve within the racklink.
* Invalid or out-of-range inputs are normalized to 0 (no additional vertical shift), giving full sleeve coverage:
*   - start >= end          → 0 (custom range ignored, full coverage)
*   - start >= total_length → 0 (out of bounds, full coverage)
* A valid offset applies a vertical shift relative to the default position:
*   - start < 0  → sleeve is shifted downward
*   - start > 0  → sleeve is shifted upward
* Returns start * BASE_UNIT.
*/
function get_sleeve_start_offset(start, end, total_length) =
  (start >= end || start >= total_length) ? 0 : start * BASE_UNIT;

/**
* Calculates the sleeve length (in HR units) based on start/end positions.
* Invalid or out-of-range inputs are normalized to full coverage (total_length):
*   - start >= total_length → total_length (out of bounds, full coverage)
*   - start >= end          → total_length (invalid range ignored, full coverage)
*   - end > total_length    → total_length - start (end clamped to total_length)
* Otherwise returns end - start.
*/
function get_sleeve_length_units(start, end, total_length) =
  (start >= total_length) ? total_length : (start >= end ? total_length : (end > total_length ? (total_length - start) : (end - start)));

module racklink(height, distance, left_start=0, left_end=0, right_start=0, right_end=0,
  debug_colors=false, disable_chamfer=false) {
  assert(height > 0, "Height must be greater than 0");
  assert(distance > 0, "Distance must be greater than 0");
  assert(left_end >= 0, "left_end must not be negative");
  assert(right_end >= 0, "right_end must not be negative");

  // Warn when custom sleeve ranges are ignored (fallback to full coverage)
  if (left_start > 0 && left_start >= left_end) echo("WARNING: left_start >= left_end, ignoring custom range — using full coverage for left sleeve.");
  if (right_start > 0 && right_start >= right_end) echo("WARNING: right_start >= right_end, ignoring custom range — using full coverage for right sleeve.");

  default_offset = BASE_UNIT*1.5 + TOLERANCE/2; // default offset for the cover plate to extend beyond the sleeves

  start_left = get_sleeve_start_offset(left_start, left_end, height) + default_offset; // calculate the start offset for the left sleeve, adding the default offset for the cover plate
  start_right = get_sleeve_start_offset(right_start, right_end, height) + default_offset; // calculate the start offset for the right sleeve, adding the default offset for the cover plate
  length_left = get_sleeve_length_units(left_start, left_end, height); // calculate the length of the left sleeve based on the start and end positions
  length_right = get_sleeve_length_units(right_start, right_end, height); // calculate the length of the right sleeve based on the start and end positions

  horizontal_offset = SLEEVE_WIDTH; // horizontal offset to position the sleeves on the left and right side of the racklink, ensuring they wrap around the vertical supports of the rack columns

  cover_plate(length = height, distance = distance, debug_colors=debug_colors, disable_chamfer=disable_chamfer) {
    up(start_left) left(horizontal_offset) align(FRONT,LEFT+BOTTOM,inside=true) support_sleeve(length = length_left, debug_colors=debug_colors, disable_chamfer=disable_chamfer);
    up(start_right) right(horizontal_offset) align(FRONT,RIGHT+BOTTOM,inside=true) support_sleeve(length = length_right, debug_colors=debug_colors, disable_chamfer=disable_chamfer);
  }

}
