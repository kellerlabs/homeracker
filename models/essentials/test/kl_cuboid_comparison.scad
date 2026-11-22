// KellerLab Essentials - Cuboid Comparison
//
// Left: BOSL2 cuboid with rounded vertical edges and a chamfer mask on the top edges.
// Right: kl_cuboid with the same rounding and chamfer.

include <BOSL2/std.scad>
include <../lib/kl_cuboid.scad>

$fn = 64;

SIZE = [30, 20, 10];
ROUNDING = 4;
CHAMFER = 1.5;

xdistribute(spacing = 40) {
  diff()
    cuboid(SIZE, rounding = ROUNDING, edges = "Z")
      edge_mask(TOP)
        chamfer_edge_mask(chamfer = CHAMFER);
  kl_cuboid(SIZE, rounding = ROUNDING, chamfer = CHAMFER, chamfer_edges = [TOP]);
}
