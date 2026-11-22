// KellerLab Essentials - Print-Optimized Cuboid
//
// Customizable cuboid with rounded vertical edges and chamfered top and bottom edges.

include <../lib/kl_cuboid.scad>

/* [Size] */
width = 45;   // [1:0.5:300]
depth = 30;   // [1:0.5:300]
height = 15;  // [1:0.5:300]

/* [Rounding] */
// Radius of the rounded vertical edges
rounding = 3;  // [0:0.5:50]
round_front_left = true;
round_front_right = true;
round_back_left = true;
round_back_right = true;

/* [Chamfer] */
// Size of the top and bottom chamfers. A chamfer covers every side joined by rounded edges.
chamfer = 1;  // [0:0.1:10]
chamfer_top_front = true;
chamfer_top_right = true;
chamfer_top_back = true;
chamfer_top_left = true;
chamfer_bottom_front = true;
chamfer_bottom_right = true;
chamfer_bottom_back = true;
chamfer_bottom_left = true;

/* [Hidden] */
$fn = 100;

_rounding_edges = [
  if (round_front_left) FRONT + LEFT,
  if (round_front_right) FRONT + RIGHT,
  if (round_back_left) BACK + LEFT,
  if (round_back_right) BACK + RIGHT,
];

_chamfer_edges = [
  if (chamfer_top_front) TOP + FRONT,
  if (chamfer_top_right) TOP + RIGHT,
  if (chamfer_top_back) TOP + BACK,
  if (chamfer_top_left) TOP + LEFT,
  if (chamfer_bottom_front) BOTTOM + FRONT,
  if (chamfer_bottom_right) BOTTOM + RIGHT,
  if (chamfer_bottom_back) BOTTOM + BACK,
  if (chamfer_bottom_left) BOTTOM + LEFT,
];

kl_cuboid([width, depth, height],
  rounding = rounding, rounding_edges = _rounding_edges,
  chamfer = chamfer, chamfer_edges = _chamfer_edges,
  anchor = BOTTOM);
