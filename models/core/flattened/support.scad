include <BOSL2/std.scad>

/* [Parameters] */

// The length (Y-axis) of the support in base units.
units = 3;  // [1:1:50]

// Add x holes
x_holes = false;

/* [Debug Parameters] */
debug_colors = false;     // If true, uses bright colors to visualize different features (e.g. holes, main body) for testing purposes.
disable_chamfer = false;  // If true, disables chamfered edges for debugging and testing.

/* [Hidden] */
// --- from constants.scad ---
PRINTING_LAYER_WIDTH = 0.4;
BASE_UNIT = 15;
BASE_STRENGTH = 2;
BASE_CHAMFER = 1;
LOCKPIN_HOLE_CHAMFER = 0.8;
LOCKPIN_HOLE_SIDE_LENGTH = 4;
LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION = [LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH];
HR_YELLOW = "#f7b600";
HR_RED = "#c41e3a";
HR_GREEN = "#2d7a2e";
HR_CHARCOAL = "#333333";
// --- from kl_cuboid.scad ---
KL_CUBOID_SIDES = [FRONT, RIGHT, BACK, LEFT];
KL_CUBOID_VERTICAL_EDGES = [FRONT + RIGHT, RIGHT + BACK, BACK + LEFT, LEFT + FRONT];
KL_CUBOID_CHAMFER_EDGES = [for (face = [TOP, BOTTOM]) each concat([face], [for (side = KL_CUBOID_SIDES) face + side])];
// --- from support.scad ---
HR_CORE_SUPPORT_PRIMARY_COLOR = HR_CHARCOAL;
HR_CORE_SUPPORT_SECONDARY_COLOR = HR_YELLOW;
$fn = 100;

// --- Examples ---

// Example 1: Create a default support (uses default units and x_holes)
// support();

// Example 2: Create a support with 5 units and no x holes
// support(units=5, x_holes=false);

// Example 3: Create a support with units and x_holes as set above
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
    assert(in_list(edge, KL_CUBOID_CHAMFER_EDGES), str("kl_cuboid: chamfer_edges takes top or bottom edges or faces only, got ", edge));
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
module support(units = 3, x_holes = false,
  debug_colors = false, disable_chamfer = false,
  anchor = CENTER, spin = 0, orient = UP) {

  support_dimensions = [BASE_UNIT, BASE_UNIT * units, BASE_UNIT];
  attachable(anchor = anchor, spin = spin, orient = orient, size = support_dimensions) {
    difference() {

      color(debug_colors ? HR_YELLOW : HR_CORE_SUPPORT_PRIMARY_COLOR)
        kl_cuboid(support_dimensions, chamfer = disable_chamfer ? 0 : BASE_CHAMFER, rounding = BASE_STRENGTH);

      ycopies(spacing = BASE_UNIT, n = units) {

        color(debug_colors ? HR_RED : HR_CORE_SUPPORT_PRIMARY_COLOR) lockpin_hole_support();
      }
      if (x_holes) {
        ycopies(spacing = BASE_UNIT, n = units) {

          color(debug_colors ? HR_RED : HR_CORE_SUPPORT_PRIMARY_COLOR) rotate([0, 90, 0]) lockpin_hole_support();
        }
      }
    }
    children();
  }
}
module lockpin_hole_support(
  disable_chamfer = false, debug_colors = false) {
  lock_pin_center_side = LOCKPIN_HOLE_SIDE_LENGTH + PRINTING_LAYER_WIDTH * 2;
  lock_pin_center_dimension = [lock_pin_center_side, lock_pin_center_side];

  lock_pin_outer_side = LOCKPIN_HOLE_SIDE_LENGTH + (disable_chamfer ? 0 : LOCKPIN_HOLE_CHAMFER * 2);
  lock_pin_outer_dimension = [lock_pin_outer_side, lock_pin_outer_side];

  lock_pin_prismoid_inner_length = BASE_UNIT / 2 - LOCKPIN_HOLE_CHAMFER;
  lock_pin_prismoid_outer_length = LOCKPIN_HOLE_CHAMFER;

  attachable_side_length = disable_chamfer ? lock_pin_center_side : lock_pin_outer_side;
  attachable_height_half = lock_pin_prismoid_inner_length + lock_pin_prismoid_outer_length;

  module hole_half(anchor = CENTER, spin = 0, orient = UP) {
    attachable(anchor = anchor, spin = spin, orient = orient, size = [attachable_side_length, attachable_side_length, attachable_height_half]) {
      down(attachable_height_half / 2)
        color_this(debug_colors ? HR_GREEN : HR_CORE_SUPPORT_SECONDARY_COLOR)
          prismoid(size1 = lock_pin_center_dimension, size2 = LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION, h = lock_pin_prismoid_inner_length) {
            attach(TOP, BOTTOM) color_this(debug_colors ? HR_RED : HR_CORE_SUPPORT_SECONDARY_COLOR)
              prismoid(size1 = LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION, size2 = lock_pin_outer_dimension, h = lock_pin_prismoid_outer_length);
          }
      children();
    }
  }

  attachable(anchor = CENTER, spin = 0, orient = UP, size = [attachable_side_length, attachable_side_length, attachable_height_half * 2]) {
    up(attachable_height_half / 2)
      hole_half() {
        attach(BOTTOM, BOTTOM) hole_half();
      }
    children();
  }
}

support(units = units, x_holes = x_holes, debug_colors = debug_colors, disable_chamfer = disable_chamfer);
