// HomeRacker - Vent Library
//
// This file is part of HomeRacker implementation by KellerLab.
// It contains the vent module, meant to be placed in panels (diff).
// It shall provide proper ventilation, allowing air to flow through the panel.

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

module hexagon3d(side_length, height,
  anchor=CENTER, spin=0, orient=UP,
  debug_colors=false, chamfer_enabled=true) {

  // Calculate bounding box for BOSL2 attachable
  // For a hexagon with side=side_length:
  // point-to-point width = 2 * side_length
  // flat-to-flat width = sqrt(3) * side_length
  size = [2 * side_length, sqrt(3) * side_length, height];

  // Custom anchors for the 6 flat faces
  // hexagon() has vertices on the X axis, so flats are at 30, 90, 150, 210, 270, 330 degrees
  r_flat = side_length * sqrt(3) / 2;
  face_names = [
    "face_back_right", // 30 degrees
    "face_back",       // 90 degrees
    "face_back_left",  // 150 degrees
    "face_front_left", // 210 degrees
    "face_front",      // 270 degrees
    "face_front_right" // 330 degrees
  ];
  face_anchors = [
    for (i = [0:5])
      let (a = 30 + i*60)
      named_anchor(face_names[i], [r_flat * cos(a), r_flat * sin(a), 0], [cos(a), sin(a), 0], 0)
  ];

  attachable(anchor=anchor, spin=spin, orient=orient, size=size, anchors=face_anchors) {
    linear_extrude(h=height, center=true) {
      hexagon(side=side_length);
    }
    children();
  }
}

module hexgrid(width, depth, height, side_length=8, wall_strength=2) {
  // Distance from center to flat face
  r_flat = side_length * sqrt(3) / 2;
  // Center-to-center distance between adjacent hexes sharing a wall
  spacing = 2 * r_flat + wall_strength;

  // X distance between columns and Y distance between rows when stagger="alt"
  dx = spacing * sqrt(3) / 2;
  dy = spacing;

  // Calculate required amount of hexes to fully cover width and depth
  // Adding +2 ensures the grid safely overhangs the boundaries for reliable cutting
  cols = ceil(width / dx) + 2;
  rows = ceil(depth / dy) + 2;

  // Center offsets to keep the grid centered at [0,0]
  x_offset = (cols - 1) * dx / 2;
  y_offset = ((rows - 1) * dy + dy / 2) / 2;

  // Manually generate the staggered grid to ensure correct 30°/90° alignment
  for (col = [0 : cols - 1]) {
    for (row = [0 : rows - 1]) {
      x = col * dx - x_offset;
      y = row * dy + (col % 2 == 1 ? dy / 2 : 0) - y_offset;
      translate([x, y, 0])
        hexagon3d(side_length=side_length, height=height);
    }
  }
}

hexgrid(width=50,depth=40,height=2, side_length=5, wall_strength=2);

//hexagon3d(side_length=20, height=5) show_anchors();
