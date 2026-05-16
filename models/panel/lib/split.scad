// HomeRacker - Panel Split Library
//
// This library contains the split module used to create a vertical split in panels,
// allowing for printing in multiple parts (e.g. 19" rack panels).
// The split module creates a vertical cut on the body it's attached to
// and adds connecting features (basically a vertical support + sleeve)

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
include <../../core/lib/support.scad>

units = 2; // [2:1:8]
debug_colors = true; // [false,true]
enable_chamfer = true; // [false,true]

// units as in HomeRacker units (15mm)
module split_connector(units=2,
  debug_colors=false, chamfer_enabled=true) {
  assert(units > 1, "Split connector requires more than 1 unit");

  zrot(90)
  support(units=units,x_holes=false, debug_colors=debug_colors, disable_chamfer=!chamfer_enabled, orient=FRONT);
}



split_connector(units=2, debug_colors=debug_colors, chamfer_enabled=enable_chamfer);
