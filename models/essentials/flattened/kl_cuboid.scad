include <BOSL2/std.scad>

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
// --- from kl_cuboid.scad ---
KL_CUBOID_SIDES = [FRONT, RIGHT, BACK, LEFT];
KL_CUBOID_VERTICAL_EDGES = [FRONT + RIGHT, RIGHT + BACK, BACK + LEFT, LEFT + FRONT];
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
function kl_cuboid_chamfered_sides(face, rounding_edges, chamfer_edges) =
  let(
    _requested = [for (side = KL_CUBOID_SIDES) in_list(face, chamfer_edges) || in_list(face + side, chamfer_edges)],
    _rounded = [for (edge = KL_CUBOID_VERTICAL_EDGES) in_list(edge, rounding_edges)]
  )
  _kl_cuboid_chain(_requested, _rounded, 3);
function _kl_cuboid_chain(chamfered, rounded, passes) =
  passes == 0 ? chamfered
  : _kl_cuboid_chain(
    [for (i = [0:3]) chamfered[i] || (rounded[i] && chamfered[(i + 1) % 4]) || (rounded[(i + 3) % 4] && chamfered[(i + 3) % 4])],
    rounded, passes - 1
  );
function _kl_cuboid_outline(size, rounding, rounded, chamfered, grow) =
  let(
    _grow = [for (side_chamfered = chamfered) side_chamfered ? 0 : grow],
    _corner_rounding = [for (i = [1, 2, 3, 0]) rounded[i] ? rounding : 0]
  )
  move(
    [(_grow[1] - _grow[3]) / 2, (_grow[2] - _grow[0]) / 2],
    rect([size.x + _grow[1] + _grow[3], size.y + _grow[0] + _grow[2]], rounding = _corner_rounding)
  );
module kl_cuboid(size, rounding = 0, rounding_edges = KL_CUBOID_VERTICAL_EDGES,
  chamfer = 0, chamfer_edges = [TOP, BOTTOM],
  anchor = CENTER, spin = 0, orient = UP) {
  _size = scalar_vec3(size);
  for (edge = rounding_edges)
    assert(in_list(edge, KL_CUBOID_VERTICAL_EDGES), str("kl_cuboid: rounding_edges takes vertical edges only, got ", edge));
  for (edge = chamfer_edges)
    assert(
      abs(edge.z) == 1 && norm([edge.x, edge.y]) <= 1 && edge.x * edge.y == 0,
      str("kl_cuboid: chamfer_edges takes top or bottom edges or faces only, got ", edge)
    );
  assert(rounding >= 0 && 2 * rounding <= min(_size.x, _size.y), "kl_cuboid: rounding must fit the footprint");
  assert(chamfer >= 0 && 2 * chamfer <= _size.z, "kl_cuboid: chamfer must fit the height");

  _rounding_edges = rounding > 0 ? rounding_edges : [];
  _rounded = [for (edge = KL_CUBOID_VERTICAL_EDGES) in_list(edge, _rounding_edges)];
  _bottom_sides = kl_cuboid_chamfered_sides(BOTTOM, _rounding_edges, chamfer_edges);
  _top_sides = kl_cuboid_chamfered_sides(TOP, _rounding_edges, chamfer_edges);
  _grow = 2 * chamfer + 1;

  attachable(anchor = anchor, spin = spin, orient = orient, size = _size) {
    intersection() {
      linear_sweep(_kl_cuboid_outline(_size, rounding, _rounded, [true, true, true, true], 0), height = _size.z, center = true);

      offset_sweep(
        _kl_cuboid_outline(_size, rounding, _rounded, _bottom_sides, _grow), height = _size.z,
        bottom = chamfer > 0 && any(_bottom_sides) ? os_chamfer(width = chamfer) : undef,
        anchor = "origin"
      );
      offset_sweep(
        _kl_cuboid_outline(_size, rounding, _rounded, _top_sides, _grow), height = _size.z,
        top = chamfer > 0 && any(_top_sides) ? os_chamfer(width = chamfer) : undef,
        anchor = "origin"
      );
    }
    children();
  }
}

kl_cuboid([width, depth, height],
  rounding = rounding, rounding_edges = _rounding_edges,
  chamfer = chamfer, chamfer_edges = _chamfer_edges,
  anchor = BOTTOM);
