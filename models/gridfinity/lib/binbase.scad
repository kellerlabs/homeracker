// Gridfinity - Bin Base
//
// This file is part of the Gridfinity implementation by KellerLab
// It contains a bin base grid module.
// The bin base is used as the bottom part of bins or any other Gridfinity compatible body.
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


// IMPORTANT
//
// The specification has been taken from Printables
// grizzie17's specification was the most precise available, specifically regarding the roundings
// https://www.printables.com/model/417152-gridfinity-specification

include <BOSL2/std.scad>
include <../../core/lib/constants.scad>
include <../lib/constants.scad>

// all units in mm

BB_BOTTOM_LIP_SIDE_LENGTH = 35.8; // mid part side length - bottom lip height * 2
BB_BOTTOM_LIP_ROUNDING = 0.8; // radius
BB_BOTTOM_LIP_HEIGHT = 0.8;

BB_MID_PART_SIDE_LENGTH = 37.2; // top side length - top height * 2
BB_MID_PART_ROUNDING = 1.6; // radius
BB_MID_PART_HEIGHT = 1.8;
BB_TOP_PART_SIDE_LENGTH = 41.5;
BB_TOP_PART_ROUNDING = 3.75; // radius
BB_TOP_PART_HEIGHT = 2.15;

BB_HEIGHT = BB_BOTTOM_LIP_HEIGHT+BB_MID_PART_HEIGHT+BB_TOP_PART_HEIGHT;

module binbase_cell() {
  prismoid(BB_BOTTOM_LIP_SIDE_LENGTH, BB_MID_PART_SIDE_LENGTH, rounding1=BB_BOTTOM_LIP_ROUNDING, rounding2=BB_MID_PART_ROUNDING, h=BB_BOTTOM_LIP_HEIGHT)
    attach(TOP,BOTTOM) cuboid([BB_MID_PART_SIDE_LENGTH, BB_MID_PART_SIDE_LENGTH, BB_MID_PART_HEIGHT], rounding=BB_MID_PART_ROUNDING, except=[BOTTOM,TOP])
    attach(TOP,BOTTOM) prismoid(BB_MID_PART_SIDE_LENGTH, BB_TOP_PART_SIDE_LENGTH, rounding1=BB_MID_PART_ROUNDING, rounding2=BB_TOP_PART_ROUNDING, h=BB_TOP_PART_HEIGHT);
}

/** Bin Base Grid
  Creates a grid of bin base cells according to the Gridfinity specification.
  Note that cell spacing is according to the Gridfinity base unit (42mm) even though the cells themselves are smaller.
  So the outer length of one dimension of the grid is units_x|y * 42mm - 0.5mm.
  @param units_x Number of grid units in X direction (1 unit = 42mm)
  @param units_y Number of grid units in Y direction (1 unit = 42mm)
*/
module binbase(units_x=1, units_y=1, anchor=CENTER, spin=0, orient=UP) {
  assert(is_int(units_x), "units_x must be an integer");
  assert(is_int(units_y), "units_y must be an integer");
  assert(units_x >= 1, "units_x must be at least 1");
  assert(units_y >= 1, "units_y must be at least 1");
  // total height of the binbase
  basebin_dimensions = [BB_TOP_PART_SIDE_LENGTH*units_x - BINBASE_SUBTRACTOR, BB_TOP_PART_SIDE_LENGTH*units_y - BINBASE_SUBTRACTOR, BB_HEIGHT];


  // Grid of cutouts, also anchored to bottom for alignment
  attachable(anchor, spin, orient, size=basebin_dimensions){
    grid_copies(n=[units_x, units_y], spacing=GRIDFINITY_BASE_UNIT)
      binbase_cell();
    children();
  }
}

module binbase_with_topplate(units_x=1, units_y=1, topplate_thickness=2, anchor=CENTER, spin=0, orient=UP) {

  length_x = GRIDFINITY_BASE_UNIT*units_x-BINBASE_SUBTRACTOR;
  length_y = GRIDFINITY_BASE_UNIT*units_y-BINBASE_SUBTRACTOR;
  height_total = BB_HEIGHT + topplate_thickness;

  attachable(anchor, spin, orient, size=[length_x, length_y, height_total]) {
    down(height_total/2)
    binbase(units_x, units_y) attach(TOP,BOTTOM)
    attach(TOP,BOTTOM)
      cuboid([length_x, length_y, topplate_thickness],
      rounding=BB_TOP_PART_ROUNDING, except=[BOTTOM,TOP]);
    children();
  }
}
