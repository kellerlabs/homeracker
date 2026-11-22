// KellerLab Essentials - Print-Optimized Cuboid
//
// A cuboid that rounds vertical edges and chamfers top and bottom edges, combined on one body.
// A rounded vertical edge joins its two sides into one chain, and a chamfer always covers a whole chain,
// so the chamfer follows the rounding.
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

// Sides in perimeter order; corner i joins side i and side i + 1.
KL_CUBOID_SIDES = [FRONT, RIGHT, BACK, LEFT];
KL_CUBOID_VERTICAL_EDGES = [FRONT + RIGHT, RIGHT + BACK, BACK + LEFT, LEFT + FRONT];
KL_CUBOID_CHAMFER_EDGES = [for (face = [TOP, BOTTOM]) each concat([face], [for (side = KL_CUBOID_SIDES) face + side])];

/**
 * 🔗 kl_cuboid_chamfered_sides
 *
 * Public, for consumers that need the chain rule without the geometry (e.g. to place matching masks).
 * Applies the chain rule to one face: a chamfer requested on one side spreads to every side joined by a rounded corner.
 *
 * Parameters:
 *   face (vector): TOP or BOTTOM.
 *   rounding_edges (list): Rounded vertical edges, e.g. [FRONT + LEFT].
 *   chamfer_edges (list): Top or bottom edges (e.g. BOTTOM + FRONT) or whole faces (TOP, BOTTOM).
 *
 * Returns:
 *   Four booleans for [FRONT, RIGHT, BACK, LEFT], true where that side of the face gets chamfered.
 */
function kl_cuboid_chamfered_sides(face, rounding_edges, chamfer_edges) =
  let(
    _requested = [for (side = KL_CUBOID_SIDES) in_list(face, chamfer_edges) || in_list(face + side, chamfer_edges)],
    _rounded = [for (edge = KL_CUBOID_VERTICAL_EDGES) in_list(edge, rounding_edges)]
  )
  _kl_cuboid_chain(_requested, _rounded, 3);

/**
 * _kl_cuboid_chain
 *
 * Internal, called by kl_cuboid_chamfered_sides.
 * Spreads chamfers across rounded corners, one neighbor per pass; three passes reach around all four sides.
 *
 * Parameters:
 *   chamfered (list): Four booleans for [FRONT, RIGHT, BACK, LEFT], the sides chamfered so far.
 *   rounded (list): Four booleans, true where corner i (between side i and side i + 1) is rounded.
 *   passes (int): Remaining spread passes.
 *
 * Returns:
 *   Four booleans for [FRONT, RIGHT, BACK, LEFT] with the chamfer spread along every chain.
 */
function _kl_cuboid_chain(chamfered, rounded, passes) =
  passes == 0 ? chamfered
  : _kl_cuboid_chain(
    [for (i = [0:3]) chamfered[i] || (rounded[i] && chamfered[(i + 1) % 4]) || (rounded[(i + 3) % 4] && chamfered[(i + 3) % 4])],
    rounded, passes - 1
  );

/**
 * _kl_cuboid_outline
 *
 * Internal, called by kl_cuboid.
 * Builds the 2D footprint and grows every unchamfered side outward, so a full-perimeter chamfer only lands on chamfered sides.
 *
 * Parameters:
 *   size (vector): [x, y, z] of the cuboid; only x and y are used.
 *   rounding (number): Corner radius of the rounded vertical edges.
 *   rounded (list): Four booleans, true where corner i (between side i and side i + 1) is rounded.
 *   chamfered (list): Four booleans for [FRONT, RIGHT, BACK, LEFT], true where the side gets chamfered.
 *   grow (number): Distance to push each unchamfered side outward.
 *
 * Returns:
 *   A 2D path centered on the original footprint.
 */
function _kl_cuboid_outline(size, rounding, rounded, chamfered, grow) =
  let(
    _grow = [for (side_chamfered = chamfered) side_chamfered ? 0 : grow],  // [FRONT, RIGHT, BACK, LEFT]
    _corner_rounding = [for (i = [1, 2, 3, 0]) rounded[i] ? rounding : 0]  // rect() order: X+Y+, X-Y+, X-Y-, X+Y-
  )
  move(
    [(_grow[1] - _grow[3]) / 2, (_grow[2] - _grow[0]) / 2],
    rect([size.x + _grow[1] + _grow[3], size.y + _grow[0] + _grow[2]], rounding = _corner_rounding)
  );

/**
 * 🧊 kl_cuboid
 *
 * Public, the module consumers call. BOSL2 attachable.
 * Print-optimized cuboid: rounds vertical edges and chamfers top and bottom edges on one body.
 * Chamfering one side of a chain chamfers the whole chain on that face.
 *
 * Parameters:
 *   size (number|vector): [x, y, z] in mm, or one number for a cube.
 *   rounding (number, default=0): Radius of the rounded vertical edges.
 *   rounding_edges (list, default=all four): Vertical edges to round, e.g. [FRONT + LEFT].
 *   chamfer (number, default=0): Chamfer size of the top and bottom edges.
 *   chamfer_edges (list, default=[TOP, BOTTOM]): Top or bottom edges (e.g. BOTTOM + FRONT) or whole faces.
 *   anchor, spin, orient: BOSL2 attachment, see https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad
 *
 * Produces:
 *   A solid sized like cuboid(size), with children attached to it.
 *
 * Usage:
 *   kl_cuboid([45, 30, 15], rounding = 3, chamfer = 1);
 */
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
      // anchor "origin" keeps the path's XY and centers the sweep on Z
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
