// HomeRacker - Sleeve
//
// This file is part of HomeRacker implementation by KellerLab.
// It contains the sleeve module — a general-purpose 3-sided U-shaped sleeve
// that slides onto a HomeRacker support. Lock pin holes on both sides allow
// securing it in place.
//
// Use cases: connecting rack columns (Racklink), labeling rack sections, or
//            any accessory that needs to attach to a HomeRacker support.
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

// Hidden constants for sleeve library (no Customizer section marker)
HR_SLEEVE_PRIMARY_COLOR = HR_YELLOW;
SLEEVE_WIDTH = BASE_UNIT + 2*BASE_STRENGTH + TOLERANCE;

module sleeve(length, color=HR_SLEEVE_PRIMARY_COLOR, debug_colors=false, disable_chamfer=false, anchor=CENTER, orient=UP, spin=0) {
  assert(is_int(length) && length > 0, "Length must be a positive integer");

  attachable_width = SLEEVE_WIDTH;
  attachable_depth = BASE_UNIT + BASE_STRENGTH + TOLERANCE/2;
  attachable_height = length * BASE_UNIT - TOLERANCE;
  inner_back_y = -attachable_depth/2 + BASE_STRENGTH;
  // override BACK anchor to align with inner back of sleeve for better attachment to supports
  override = function (anchor)
      anchor != [0,1,0] ? undef
      : [[0, inner_back_y, 0]];
  tag_scope("sleeve")
  attachable(anchor=anchor, orient=orient, spin=spin, size=[attachable_width, attachable_depth, attachable_height], override=override){
    color_this(debug_colors ? HR_GREEN : color)
    diff()
    cuboid([attachable_width, attachable_depth, attachable_height], chamfer=disable_chamfer ? 0 : BASE_CHAMFER){
      align(BACK, inside=true) tag("remove") color_this(debug_colors ? HR_WHITE : color) cuboid([BASE_UNIT+TOLERANCE, BASE_UNIT+TOLERANCE/2, attachable_height+HR_EPSILON]);
      zcopies(BASE_UNIT,n=length) tag("remove") back((BASE_STRENGTH+TOLERANCE/2)/2)
      color(debug_colors ? HR_RED : color) rotate([0,90,0])
      lockpin_hole(depth=attachable_width+HR_EPSILON, chamfer_top=!disable_chamfer, chamfer_bottom=!disable_chamfer);
    }
    children();
  }
}
