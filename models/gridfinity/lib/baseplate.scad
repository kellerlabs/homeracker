// Gridfinity - Baseplate
//
// This file is part of the Gridfinity implementation by KellerLab
// It contains the baseplate module to create baseplates of arbitrary size
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

module baseplate_cutout() {
  prismoid(GRIDFINITY_BP_BOTTOM_LIP_SIDE_LENGTH, GRIDFINITY_BP_MID_PART_SIDE_LENGTH, rounding1=GRIDFINITY_BP_BOTTOM_LIP_ROUNDING, rounding2=GRIDFINITY_BP_MID_PART_ROUNDING, h=GRIDFINITY_BP_BOTTOM_LIP_HEIGHT)
    attach(TOP,BOTTOM) cuboid([GRIDFINITY_BP_MID_PART_SIDE_LENGTH, GRIDFINITY_BP_MID_PART_SIDE_LENGTH, GRIDFINITY_BP_MID_PART_HEIGHT], rounding=GRIDFINITY_BP_MID_PART_ROUNDING, except=[BOTTOM,TOP])
    attach(TOP,BOTTOM) prismoid(GRIDFINITY_BP_MID_PART_SIDE_LENGTH, GRIDFINITY_BP_TOP_PART_SIDE_LENGTH, rounding1=GRIDFINITY_BP_MID_PART_ROUNDING, rounding2=GRIDFINITY_BP_TOP_PART_ROUNDING, h=GRIDFINITY_BP_TOP_PART_HEIGHT);
}

module baseplate(units_x=1, units_y=1) {
  assert(is_int(units_x), "units_x must be an integer");
  assert(is_int(units_y), "units_y must be an integer");
  assert(units_x >= 1, "units_x must be at least 1");
  assert(units_y >= 1, "units_y must be at least 1");
  // total height of the baseplate minus two layer heights for better printability. Avoids sharp top edges.
  BASEPLATE_HEIGHT = GRIDFINITY_BP_BOTTOM_LIP_HEIGHT+GRIDFINITY_BP_MID_PART_HEIGHT+GRIDFINITY_BP_TOP_PART_HEIGHT-PRINTING_LAYER_HEIGHT*3;
  baseplate_dimensions = [GRIDFINITY_BP_TOP_PART_SIDE_LENGTH*units_x, GRIDFINITY_BP_TOP_PART_SIDE_LENGTH*units_y, BASEPLATE_HEIGHT];

  // went with difference() instead of diff() to increase performance
  difference() {
    // Single baseplate block, anchored to bottom
    cuboid(baseplate_dimensions, rounding=GRIDFINITY_BP_TOP_PART_ROUNDING, except=[TOP,BOTTOM], anchor=BOTTOM);

    // Grid of cutouts, also anchored to bottom for alignment
    grid_copies(n=[units_x, units_y], spacing=GRIDFINITY_BP_TOP_PART_SIDE_LENGTH)
      baseplate_cutout();
  }
}
