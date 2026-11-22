// KellerLab Essentials - Print-Optimized Cuboid Test
//
// Asserts the chamfer chain rule and renders one cuboid per case.

include <BOSL2/std.scad>
include <../lib/kl_cuboid.scad>

$fn = 32;

// [FRONT, RIGHT, BACK, LEFT]
NONE = [false, false, false, false];
ALL = [true, true, true, true];

// No rounding: only the requested side
assert(kl_cuboid_chamfered_sides(BOTTOM, [], [BOTTOM + FRONT]) == [true, false, false, false], "sharp corners keep the chamfer on its side");

// A whole face chamfers every side
assert(kl_cuboid_chamfered_sides(TOP, [], [TOP]) == ALL, "face chamfers all sides");
assert(kl_cuboid_chamfered_sides(BOTTOM, [], [TOP]) == NONE, "top chamfer leaves the bottom sharp");

// One rounding joins two sides, from either side
assert(kl_cuboid_chamfered_sides(BOTTOM, [FRONT + LEFT], [BOTTOM + FRONT]) == [true, false, false, true], "front chain reaches left");
assert(kl_cuboid_chamfered_sides(BOTTOM, [FRONT + LEFT], [BOTTOM + LEFT]) == [true, false, false, true], "left chain reaches front");

// Two roundings join three sides
assert(kl_cuboid_chamfered_sides(TOP, [FRONT + LEFT, FRONT + RIGHT], [TOP + LEFT]) == [true, true, false, true], "chain over two roundings");

// Three roundings join all four sides, starting at the far end
assert(kl_cuboid_chamfered_sides(TOP, [FRONT + RIGHT, RIGHT + BACK, BACK + LEFT], [TOP + FRONT]) == ALL, "chain over three roundings");

// Each face follows its own requests
assert(kl_cuboid_chamfered_sides(TOP, [FRONT + LEFT], [BOTTOM + BACK, TOP + FRONT]) == [true, false, false, true], "top chain");
assert(kl_cuboid_chamfered_sides(BOTTOM, [FRONT + LEFT], [BOTTOM + BACK, TOP + FRONT]) == [false, false, true, false], "bottom chain");

// The rounding edges decide the axis; without them a whole-face chamfer does; otherwise Z
assert(kl_cuboid_axis(undef, undef) == UP, "defaults round along Z");
assert(kl_cuboid_axis([FRONT + LEFT], undef) == [0, 0, 1], "vertical edge rounds along Z");
assert(kl_cuboid_axis([LEFT + TOP, RIGHT + BOTTOM], undef) == [0, 1, 0], "edges across X and Z round along Y");
assert(kl_cuboid_axis([FRONT + TOP], undef) == [1, 0, 0], "edges across Y and Z round along X");
assert(kl_cuboid_axis([], [FRONT]) == [0, 1, 0], "a whole front face chamfer points along Y");
assert(kl_cuboid_axis([], [FRONT + TOP]) == UP, "an edge chamfer alone falls back to Z");
assert(kl_cuboid_axis([LEFT + TOP], [TOP]) == [0, 1, 0], "rounding edges outrank face chamfers");

// The canonical frame turns the axis into Z and keeps edges on whole vectors
assert(_kl_cuboid_to_axis_frame(LEFT + TOP, [0, 1, 0]) == LEFT + FRONT, "Y axis: left top edge becomes a vertical edge");
assert(_kl_cuboid_to_axis_frame(BACK, [0, 1, 0]) == TOP, "Y axis: back face becomes the top face");
assert(_kl_cuboid_to_axis_frame(RIGHT, [1, 0, 0]) == TOP, "X axis: right face becomes the top face");

// Visual: one cuboid per case, left to right
SIZE = [30, 20, 10];
xdistribute(spacing = 40) {
  kl_cuboid(SIZE, rounding = 3, chamfer = 1);
  kl_cuboid(SIZE, chamfer = 1, chamfer_edges = [BOTTOM + FRONT]);
  kl_cuboid(SIZE, rounding = 3, rounding_edges = [FRONT + LEFT], chamfer = 1, chamfer_edges = [BOTTOM + FRONT]);
  kl_cuboid(SIZE, rounding = 3, rounding_edges = [FRONT + LEFT, FRONT + RIGHT], chamfer = 1, chamfer_edges = [TOP + LEFT, BOTTOM + BACK]);
  kl_cuboid(SIZE, rounding = 3);
  // rounds along Y: left top edge rounded, front face chamfered along the chain
  kl_cuboid(SIZE, rounding = 3, rounding_edges = [LEFT + TOP], chamfer = 1, chamfer_edges = [FRONT + TOP]);
  // rounds along X: every X edge rounded, both side faces chamfered
  kl_cuboid(SIZE, rounding = 3, chamfer = 1, chamfer_edges = [LEFT, RIGHT], rounding_edges = [FRONT + TOP, TOP + BACK, BACK + BOTTOM, BOTTOM + FRONT]);
  // two corners on one side: the rounding only needs to fit that side once per corner
  kl_cuboid([12, 5, 10], rounding = 3, rounding_edges = [FRONT + LEFT, FRONT + RIGHT]);
}
