// HomeRacker - Foot Insert
//
// This file is part of HomeRacker implementation by KellerLab.
// It contains the foot module — a connector insert that provides a contact surface
// for connectors at the bottom of a rack.
// The foot plugs into any connector arm from the outside
// and adds a wider base plate for load distribution and grip.
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
include <../../core/lib/support.scad>
include <../../essentials/lib/kl_cuboid.scad>

HR_FOOT_PRIMARY_COLOR = HR_YELLOW;

/**
 * 📐 foot module
 *
 * Public, the module consumers call. BOSL2 attachable.
 * Creates a foot insert for HomeRacker connectors.
 * The foot consists of two stacked kl_cuboid parts (top to bottom), both with rounded vertical edges:
 *   1. Plug: 15mm wide, TOLERANCE/2 taller than a unit so the plate clears the arm end, lock pin holes along X and Y
 *   2. Base plate: wider platform (BASE_UNIT + BASE_STRENGTH*2 + TOLERANCE) for load distribution,
 *      its rounding concentric with the plug's
 *
 * Parameters:
 *   debug_colors (bool, default=false): Use distinct HR_ colors per section for visualization.
 *   disable_chamfer (bool, default=false): Remove chamfers from all sections; roundings stay.
 *   anchor (vector, default=CENTER): BOSL2 anchor point.
 *   spin (number, default=0): BOSL2 spin rotation.
 *   orient (vector, default=UP): BOSL2 orientation vector.
 *
 * Produces:
 *   The foot, printed upright as oriented, with children attached to its bounding box.
 *
 * Usage:
 *   foot();
 *   foot(debug_colors=true);
 *   foot(disable_chamfer=true);
 */
module foot(debug_colors = false, disable_chamfer = false,
  anchor = CENTER, spin = 0, orient = UP) {

  attachable_side_length = BASE_UNIT + BASE_STRENGTH * 2 + TOLERANCE;
  plug_height = BASE_UNIT + TOLERANCE / 2;
  attachable_height = plug_height + BASE_STRENGTH;
  chamfer = disable_chamfer ? 0 : BASE_CHAMFER;
  plate_rounding = BASE_STRENGTH + (attachable_side_length - BASE_UNIT) / 2;

  attachable(anchor = anchor, spin = spin, orient = orient, size = [attachable_side_length, attachable_side_length, attachable_height]) {
    up(BASE_STRENGTH / 2)
      diff("hole")
        color_this(debug_colors ? HR_YELLOW : HR_FOOT_PRIMARY_COLOR)
          kl_cuboid([BASE_UNIT, BASE_UNIT, plug_height], rounding = BASE_STRENGTH, chamfer = chamfer, chamfer_edges = [TOP]) {
            // holes centered on the unit, above the extra height
            tag("hole") up((plug_height - BASE_UNIT) / 2) {
              rotate([0, 90, 0]) lockpin_hole_support();
              rotate([90, 0, 0]) lockpin_hole_support();
            }
            attach(BOTTOM, TOP) color_this(debug_colors ? HR_GREEN : HR_FOOT_PRIMARY_COLOR)
              kl_cuboid([attachable_side_length, attachable_side_length, BASE_STRENGTH],
                rounding = plate_rounding, chamfer = chamfer, chamfer_edges = [BOTTOM]);
          }
    children();
  }

}
