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

// Visual: one cuboid per case, left to right
SIZE = [30, 20, 10];
xdistribute(spacing = 40) {
  kl_cuboid(SIZE, rounding = 3, chamfer = 1);
  kl_cuboid(SIZE, chamfer = 1, chamfer_edges = [BOTTOM + FRONT]);
  kl_cuboid(SIZE, rounding = 3, rounding_edges = [FRONT + LEFT], chamfer = 1, chamfer_edges = [BOTTOM + FRONT]);
  kl_cuboid(SIZE, rounding = 3, rounding_edges = [FRONT + LEFT, FRONT + RIGHT], chamfer = 1, chamfer_edges = [TOP + LEFT, BOTTOM + BACK]);
  kl_cuboid(SIZE, rounding = 3);
}
