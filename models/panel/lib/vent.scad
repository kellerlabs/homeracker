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


width=50;
depth=50;
height=2;
side_length=5;
wall_strength=2;
vent_type=0; // [0:Hex,1:Cheesegrater]
cheesegrater_rounding=0;
debug_colors=false;

/* [Hidden] */
$fn=100;

HR_VENT_PRIMARY_COLOR=HR_CHARCOAL;
HR_VENT_SECONDARY_COLOR=HR_YELLOW;

/** 3D Hexagon Geometry
 * Creates a single solid 3D hexagon pointing "up" (Z axis).
 * The hexagon is inherently oriented with flat faces pointing Left/Right,
 * and sharp corners pointing Front/Back (Y axis).
 * Exposes custom named anchors ("face_back_right", "face_back", etc.)
 * corresponding to its 6 flat sides for precise neighbor attachment.
 *
 * side_length      The length of a single hexagon edge
 * height           The Z-axis height of the extruded hexagon
 * rounding         Radius for rounding the 2D corners of the hexagon (default 0)
 * chamfer_enabled  If true, applies a small edge break (chamfer) to the top/bottom faces
 */
module hexagon3d(side_length, height, rounding=0,
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
      hexagon(side=side_length, rounding=rounding);
    }
    children();
  }
}


/** Hexagon Grid Matrix
 * Generates an interlocking 2D honeycomb grid of solid 3D hexagons that completely fills
 * a given [width, depth] boundary box. Used to cut a vent pattern out of a solid panel.
 * The bounding box math guarantees that all edge-cases are fully covered.
 *
 * width            The X-axis bounding dimension
 * depth            The Y-axis bounding dimension
 * height           The Z-axis height (thickness) of the grid
 * side_length      The edge length of individual hexagons
 * wall_strength    The distance between adjacent hexagon flat faces (the remaining solid wall when subtracted)
 * rounding         Radius for rounding the 2D corners of the hexagon (default 0)
 * ghost            If true, overlays a transparent bounding box (useful for debugging bounds logic)
 */
module hexgrid(width, depth, height, side_length=8, wall_strength=2, rounding=0,
  anchor=CENTER, spin=0, orient=UP,
  debug_colors=false,
  ghost=false) {

  // Distance from center to flat face
  r_flat = side_length * sqrt(3) / 2;
  // Center-to-center distance between adjacent hexes sharing a wall
  spacing = 2 * r_flat + wall_strength;

  attachable(anchor=anchor, spin=spin, orient=orient, size=[width, depth, height]) {
    union() {
      // By supplying a size slightly larger than the bounds, grid_copies handles the matrix natively.
      // We use 0.75 * spacing for both width and depth to tightly cover edge-cases
      // without excessive overshoots, maintaining a clean declarative BOSL2 implementation.
      zrot(90)
        grid_copies(spacing=spacing, size=[depth + 0.75*spacing, width + 0.75*spacing], stagger=true) {
          zrot(-90)
            hexagon3d(side_length=side_length, height=height, rounding=rounding);
        }
      if (ghost) {
        %cuboid([width, depth, height]);
      }
    }
    children();
  }
}


HR_VENT_TYPE_HEXAGON=0;
HR_VENT_TYPE_CHEESEGRATER=1;

/** Vent Module
 * width            The X-axis bounding dimension
 * depth            The Y-axis bounding dimension
 * height           The Z-axis height (thickness) of the vent
 * side_length      The edge length of individual hexagons
 * wall_strength    The solid wall thickness between hexes
 * vent_type        HR_VENT_TYPE_HEXAGON (0) or HR_VENT_TYPE_CHEESEGRATER (1)
 */
module vent(width, depth, height=2, side_length, wall_strength, vent_type=HR_VENT_TYPE_HEXAGON,
  cheesegrater_rounding=0,
  anchor=CENTER, spin=0, orient=UP,
  debug_colors=false
  ) {

  attachable(size=[width, depth, height], anchor=anchor, spin=spin, orient=orient) {
    tag_scope("vent")
    if(vent_type == HR_VENT_TYPE_HEXAGON) {
      diff()
      cuboid([width,depth,height]){
        if(vent_type == HR_VENT_TYPE_HEXAGON) {
          color(debug_colors ? HR_GREEN : HR_VENT_PRIMARY_COLOR)
          tag("remove") hexgrid(width = width, depth = depth, height = height+HR_EPSILON, side_length=side_length, wall_strength=wall_strength, ghost=false);
        }
      }
    } else if(vent_type == HR_VENT_TYPE_CHEESEGRATER) {
      r_flat = side_length * sqrt(3) / 2;
      spacing = 2 * r_flat + wall_strength;
      shift_x = (spacing * sqrt(3) / 2) / 3;
      shift_y = spacing / 2;

      diff()
      color(debug_colors ? HR_GREEN : HR_VENT_PRIMARY_COLOR)
      cuboid([width,depth,height]){
        tag("remove") hexgrid(width = width + spacing, depth = depth + spacing, height = height + HR_EPSILON, side_length=side_length, wall_strength=wall_strength, rounding=cheesegrater_rounding, ghost=false);
      }

      diff() down(height/4)
      color(debug_colors ? HR_RED : HR_VENT_SECONDARY_COLOR)
      cuboid([width,depth,height/2]){
        tag("remove") right(shift_x) back(shift_y)
        hexgrid(width = width + spacing, depth = depth + spacing, height = height/2 + HR_EPSILON, side_length=side_length, wall_strength=wall_strength, rounding=cheesegrater_rounding, ghost=false);
      }
    }
    children();
  }

}

//color_this(HR_YELLOW)
//cuboid([width+5,depth+5,height]);


//hexgrid(width=width,depth=depth,height=height, side_length=side_length, wall_strength=wall_strength, ghost=true) show_anchors();

diff()
color_this(debug_colors ? HR_BLUE : HR_VENT_PRIMARY_COLOR)
cuboid([width+5,depth+5,height]){
  tag("remove") color_this(HR_YELLOW) cuboid([width,depth,height+HR_EPSILON]);
  tag("keep") vent(width=width,depth=depth,height=height+HR_EPSILON,side_length=side_length,wall_strength=wall_strength,vent_type=vent_type, cheesegrater_rounding=cheesegrater_rounding, debug_colors=debug_colors);
}


// vent(width=width,depth=depth,height=height+HR_EPSILON,side_length=side_length,wall_strength=wall_strength,vent_type=vent_type,
//   debug_colors=debug_colors) show_anchors();
