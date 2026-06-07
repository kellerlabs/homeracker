// HomeRacker - Truss grid library
//
// Generic, dimension-driven triangulated stiffening lattice (a diagonal-braced
// grid / Warren-style truss). Reusable for any flat part that needs back-side
// stiffening — it knows nothing about panels, bores, or splits; it only fills a
// given [width, depth, height] box with a framed, triangulated rib lattice.
//
// Bending stiffness scales with the second moment of area (I ~ b·h³/12) and with
// material distance from the neutral axis (parallel-axis theorem I = I_c + A·d²).
// A thin skin plus tall ribs therefore behaves like an I-beam — far stiffer per
// gram than thickening the skin. Triangles are the only inherently rigid polygon,
// so the diagonals resist shear/racking that a plain rectangular grid allows.
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

// Disclaimer (even though I take ownership)
//
// DISCLAIMER: This entire truss.scad file is AI-generated (Claude Opus 4.8) from my
// requirements for a rack-panel stiffener. The idea — triangulated ribs like a truss — is mine;
// I tasked the AI with the research and the implementation. The geometry math is not the easiest
// read, and I deliberately did not review the calculations in detail: the module is a
// self-contained, black-box geometry that I only call from the outside, and its behavior meets
// all of my requirements (verified by rendering). For this kind of contained, well-specified
// geometry task I'm comfortable trusting the result without owning every line of the math.

include <BOSL2/std.scad>
include <../../core/lib/constants.scad>

/** Triangulated truss grid
 * Fills a [width, depth, height] box (X, Y, Z) with a rib lattice:
 *   - a closed perimeter frame tying the rib ends together
 *   - `rows` evenly-spaced horizontal bands; columns are auto-sized for ~square cells
 *     (so every cell is full-length — no clipped partial cells)
 *   - one 45°-ish diagonal per cell whose direction alternates in a checkerboard
 *     (Warren/zigzag), so the lattice resists racking/shear equally in both directions
 *     instead of favouring one handedness
 * All ribs are `rib` thick and span the full `depth` in Y, so when the part prints
 * face-down the ribs grow upward as solid vertical walls (no overhangs/supports).
 * When chamfered, only the outer perimeter's BACK (+Y) edge is broken — uniformly across
 * the whole back face, so rib junctions are beveled flush; interior ribs are left square.
 * BOSL2-attachable; centered in its own frame. Uncolored unless debug_colors is set,
 * so callers can wrap it in their own color_this().
 *
 * size            [width, depth, height] of the lattice box (Y = depth/protrusion)
 * rows            number of horizontal bands — drives density (more = denser/stiffer/heavier)
 * rib             rib wall thickness
 * chamfer_enabled break the outer perimeter's back edge
 */
module truss_grid(size, rows=2, rib=BASE_STRENGTH, chamfer_enabled=true,
  debug_colors=false, anchor=CENTER, spin=0, orient=UP) {

  assert(is_list(size) && len(size) == 3, "size must be a [width, depth, height] vector");
  assert(is_num(rows) && rows >= 1, "rows must be >= 1");
  assert(rib > 0, "rib must be positive");

  W = size.x;
  D = size.y;
  H = size.z;

  R = max(1, round(rows));
  row_h = H / R;
  // auto-size columns for ~square cells so triangles are evenly spread and full-length
  C = max(1, round(W / row_h));
  col_w = W / C;
  ch = chamfer_enabled ? BASE_CHAMFER : 0;

  // Square lattice (no per-piece chamfers). Attachable to its own bounding box so the
  // chamfer pass below can place edge masks on its back perimeter.
  module _lattice() {
    attachable(size=size) {
      union() {
        // perimeter frame — left/right posts run full height (own the corners),
        // top/bottom chords span between them
        for (x = [-(W-rib)/2, (W-rib)/2])
          translate([x, 0, 0]) cuboid([rib, D, H]);
        chord_w = W - 2*rib;
        if (chord_w > 0)
          for (z = [(H-rib)/2, -(H-rib)/2])
            translate([0, 0, z]) cuboid([chord_w, D, rib]);

        // interior horizontal band dividers
        if (R > 1)
          for (i = [1 : R-1]) translate([0, 0, -H/2 + i*row_h]) cuboid([W, D, rib]);

        // interior vertical column dividers
        if (C > 1)
          for (j = [1 : C-1]) translate([-W/2 + j*col_w, 0, 0]) cuboid([rib, D, H]);

        // one diagonal per cell, direction alternating in a checkerboard → balanced shear
        ang = atan2(row_h, col_w);
        diag_len = norm([col_w, row_h]) + rib;
        for (i = [0 : R-1])
          for (j = [0 : C-1]) {
            cx = -W/2 + (j + 0.5) * col_w;
            cz = -H/2 + (i + 0.5) * row_h;
            dir = (((i + j) % 2) == 0) ? 1 : -1;
            translate([cx, 0, cz])
              intersection() {
                cuboid([col_w, D + 2*HR_EPSILON, row_h]);
                yrot(dir * ang) cuboid([diag_len, D, rib]);
              }
          }
      }
      children();
    }
  }

  // Chamfer the whole lattice's outer BACK perimeter in one pass, so rib junctions are
  // beveled flush with the frame instead of leaving square nubs poking through the bevel.
  module _body() {
    if (chamfer_enabled)
      diff()
        _lattice() {
          edge_mask([BACK+TOP, BACK+BOTTOM])
            chamfer_edge_mask(l=W + 2*ch, chamfer=ch);
          edge_mask([BACK+LEFT, BACK+RIGHT])
            chamfer_edge_mask(l=H + 2*ch, chamfer=ch);
        }
    else
      _lattice();
  }

  attachable(anchor, spin, orient, size=size) {
    if (debug_colors) color(HR_GREEN) _body();
    else _body();
    children();
  }
}
