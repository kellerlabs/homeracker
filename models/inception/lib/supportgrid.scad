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

include <supportbin.scad>
include <../../core/lib/constants.scad>

/* [Basic] */
// Width of containing homeracker frame in HomeRacker units (1 unit = 15mm)
hr_width = 11; // [1:1:17]
// Height of containing homeracker frame in HomeRacker units (1 unit = 15mm)
hr_height = 3; // [1:1:10]

/* [Advanced] */
// Funnel strength of the grid (in mm)
funnel_strength = 3; // [1:0.1:5]
// Depth of the Grid in HomeRacker units (longer is more stable)
grid_depth = 1; // [1:1:5]




module supportgrid(hr_width, hr_height, funnel_strength=BASE_STRENGTH,
  grid_depth=BASE_UNIT) {

  full_grid(supports_x=hr_width, supports_y=hr_height, div_strength=funnel_strength,
    height=grid_depth*BASE_UNIT, rounding=0);
}


supportgrid(hr_width = hr_width, hr_height = hr_height, funnel_strength = funnel_strength,
  grid_depth = grid_depth);
