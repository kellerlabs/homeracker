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
BP_BOTTOM_LIP_SIDE_LENGTH = 36.3; // mid part side length - bottom lip height * 2
BP_BOTTOM_LIP_ROUNDING = 1.15; // radius
BP_BOTTOM_LIP_HEIGHT = 0.7;

BP_MID_PART_SIDE_LENGTH = 37.7; // top side length - top height * 2
BP_MID_PART_ROUNDING = 1.85; // radius
BP_MID_PART_HEIGHT = 1.8;

BP_TOP_PART_SIDE_LENGTH = GRIDFINITY_BASE_UNIT;
BP_TOP_PART_ROUNDING = 4; // radius
BP_TOP_PART_HEIGHT = 2.15;

module baseplate_cutout() {
  prismoid(BP_BOTTOM_LIP_SIDE_LENGTH, BP_MID_PART_SIDE_LENGTH, rounding1=BP_BOTTOM_LIP_ROUNDING, rounding2=BP_MID_PART_ROUNDING, h=BP_BOTTOM_LIP_HEIGHT)
    attach(TOP,BOTTOM) cuboid([BP_MID_PART_SIDE_LENGTH, BP_MID_PART_SIDE_LENGTH, BP_MID_PART_HEIGHT], rounding=BP_MID_PART_ROUNDING, except=[BOTTOM,TOP])
    attach(TOP,BOTTOM) prismoid(BP_MID_PART_SIDE_LENGTH, BP_TOP_PART_SIDE_LENGTH, rounding1=BP_MID_PART_ROUNDING, rounding2=BP_TOP_PART_ROUNDING, h=BP_TOP_PART_HEIGHT);
}

module baseplate(units_x=1, units_y=1) {
  assert(is_int(units_x), "units_x must be an integer");
  assert(is_int(units_y), "units_y must be an integer");
  assert(units_x >= 1, "units_x must be at least 1");
  assert(units_y >= 1, "units_y must be at least 1");
  // total height of the baseplate minus two layer heights for better printability. Avoids sharp top edges.
  BASEPLATE_HEIGHT = BP_BOTTOM_LIP_HEIGHT+BP_MID_PART_HEIGHT+BP_TOP_PART_HEIGHT-PRINTING_LAYER_HEIGHT*3;
  baseplate_dimensions = [BP_TOP_PART_SIDE_LENGTH*units_x, BP_TOP_PART_SIDE_LENGTH*units_y, BASEPLATE_HEIGHT];

  // went with difference() instead of diff() to increase performance
  difference() {
    // Single baseplate block, anchored to bottom
    cuboid(baseplate_dimensions, rounding=BP_TOP_PART_ROUNDING, except=[TOP,BOTTOM], anchor=BOTTOM);

    // Grid of cutouts, also anchored to bottom for alignment
    grid_copies(n=[units_x, units_y], spacing=BP_TOP_PART_SIDE_LENGTH)
      baseplate_cutout();
  }
}
