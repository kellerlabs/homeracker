// KellerLab Essentials - Print-Optimized Cuboid
//
// A cuboid that rounds the edges along one axis and chamfers the edges of the two faces across it, combined on one body.
// A rounded edge joins its two sides into one chain, and a chamfer always covers a whole chain,
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
 * 🧭 kl_cuboid_axis
 *
 * Public, for consumers that need to know which axis a kl_cuboid call rounds along.
 * Infers the axis from the edges: every rounding edge runs along it; without roundings, a whole-face chamfer points along it.
 *
 * Parameters:
 *   rounding_edges (list|undef): Rounded edges, e.g. [FRONT + LEFT] runs along Z.
 *   chamfer_edges (list|undef): Chamfered edges or whole faces, e.g. [TOP] points along Z.
 *
 * Returns:
 *   The axis as a positive unit vector ([1, 0, 0], [0, 1, 0] or [0, 0, 1]); [0, 0, 1] when the edges don't decide it.
 */
function kl_cuboid_axis(rounding_edges, chamfer_edges) =
  let(
    _rounding_axes = [for (edge = default(rounding_edges, []))[for (c = edge) c == 0 ? 1 : 0]],
    _face_axes = [for (edge = default(chamfer_edges, [])) if (len([for (c = edge) if (c != 0) c]) == 1)[for (c = edge) abs(c)]]
  )
  len(_rounding_axes) > 0 ? _rounding_axes[0]
  : len(_face_axes) > 0 ? _face_axes[0]
  : UP;

/**
 * _kl_cuboid_to_axis_frame
 *
 * Internal, called by kl_cuboid.
 * Turns a direction from the caller's frame into the canonical frame, where the rounding axis is Z.
 *
 * Parameters:
 *   direction (vector): An edge, face or size vector in the caller's frame.
 *   axis (vector): The rounding axis, from kl_cuboid_axis.
 *
 * Returns:
 *   The direction in the canonical frame, rounded to whole numbers for edges and faces.
 */
function _kl_cuboid_to_axis_frame(direction, axis) = [for (c = rot(from = axis, to = UP, p = direction)) round(c * 1e6) / 1e6];

/**
 * 🧊 kl_cuboid
 *
 * Public, the module consumers call. BOSL2 attachable.
 * Rounds the edges along one axis and chamfers the edges of the two faces across it, on one body.
 * The axis follows from the edges (see kl_cuboid_axis); the default is Z, so the calls without edges round vertical edges.
 * Chamfering one side of a chain chamfers the whole chain on that face.
 * For printing, pick the axis that points up on the bed: roundings then avoid corner bulges, chamfers avoid layer steps.
 *
 * Parameters:
 *   size (number|vector): [x, y, z] in mm, or one number for a cube.
 *   rounding (number, default=0): Radius of the rounded edges.
 *   rounding_edges (list, default=all four along the axis): Edges to round, all along one axis, e.g. [FRONT + LEFT].
 *   chamfer (number, default=0): Chamfer size.
 *   chamfer_edges (list, default=both faces across the axis): Edges on a face across the axis (e.g. BOTTOM + FRONT) or whole faces.
 *   anchor, spin, orient: BOSL2 attachment, see https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad
 *
 * Produces:
 *   A solid sized like cuboid(size), with children attached to it.
 *
 * Usage:
 *   kl_cuboid([45, 30, 15], rounding = 3, chamfer = 1);
 *   kl_cuboid([20, 10, 30], rounding = 2, rounding_edges = [LEFT + TOP], chamfer = 1, chamfer_edges = [FRONT + TOP]);  // rounds along Y
 */
module kl_cuboid(size, rounding = 0, rounding_edges, chamfer = 0, chamfer_edges,
  anchor = CENTER, spin = 0, orient = UP) {
  _size = scalar_vec3(size);
  _axis = kl_cuboid_axis(rounding_edges, chamfer_edges);
  for (edge = default(rounding_edges, []))
    assert(
      len([for (c = edge) if (abs(c) == 1) c]) == 2 && [for (c = edge) c == 0 ? 1 : 0] == _axis,
      str("kl_cuboid: rounding_edges must all run along one axis, got ", edge)
    );

  // canonical frame: the rounding axis is Z, so the geometry below only knows vertical roundings
  _axis_size = [for (c = _kl_cuboid_to_axis_frame(_size, _axis)) abs(c)];
  _axis_rounding_edges = is_undef(rounding_edges) ? KL_CUBOID_VERTICAL_EDGES : [for (edge = rounding_edges) _kl_cuboid_to_axis_frame(edge, _axis)];
  _axis_chamfer_edges = is_undef(chamfer_edges) ? [TOP, BOTTOM] : [for (edge = chamfer_edges) _kl_cuboid_to_axis_frame(edge, _axis)];
  for (i = idx(_axis_chamfer_edges))
    assert(in_list(_axis_chamfer_edges[i], KL_CUBOID_CHAMFER_EDGES), str("kl_cuboid: chamfer_edges must lie on a face across the rounding axis, got ", chamfer_edges[i]));
  assert(chamfer >= 0 && 2 * chamfer <= _axis_size.z, "kl_cuboid: chamfer must fit the length along the axis");

  _rounding_edges = rounding > 0 ? _axis_rounding_edges : [];
  _rounded = [for (edge = KL_CUBOID_VERTICAL_EDGES) in_list(edge, _rounding_edges)];
  // each side holds the roundings of its two corners (corner i joins side i and i + 1); FRONT and BACK run along X
  _side_lengths = [_axis_size.x, _axis_size.y, _axis_size.x, _axis_size.y];
  for (i = [0:3])
    assert(
      rounding >= 0 && rounding * ((_rounded[(i + 3) % 4] ? 1 : 0) + (_rounded[i] ? 1 : 0)) <= _side_lengths[i],
      "kl_cuboid: rounding must fit the cross-section"
    );
  _bottom_sides = kl_cuboid_chamfered_sides(BOTTOM, _rounding_edges, _axis_chamfer_edges);
  _top_sides = kl_cuboid_chamfered_sides(TOP, _rounding_edges, _axis_chamfer_edges);
  _grow = 2 * chamfer + 1;

  attachable(anchor = anchor, spin = spin, orient = orient, size = _size) {
    rot(from = UP, to = _axis)
      intersection() {
        linear_sweep(_kl_cuboid_outline(_axis_size, rounding, _rounded, [true, true, true, true], 0), height = _axis_size.z, center = true);
        // anchor "origin" keeps the path's XY and centers the sweep on Z
        offset_sweep(
          _kl_cuboid_outline(_axis_size, rounding, _rounded, _bottom_sides, _grow), height = _axis_size.z,
          bottom = chamfer > 0 && any(_bottom_sides) ? os_chamfer(width = chamfer) : undef,
          anchor = "origin"
        );
        offset_sweep(
          _kl_cuboid_outline(_axis_size, rounding, _rounded, _top_sides, _grow), height = _axis_size.z,
          top = chamfer > 0 && any(_top_sides) ? os_chamfer(width = chamfer) : undef,
          anchor = "origin"
        );
      }
    children();
  }
}
