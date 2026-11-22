// HomeRacker - Rackmount Adapter End Cover
//
// Closes the top or bottom of a rack between the left and right rackmount adapter.
// Its tongues slide into the adapters' end cover docks from the back.
//
// Claude implemented this end cover and the end_cover_hook it shares with the adapter's docks, to my specs.
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

include <rackmount_adapter.scad>

hr_rackmount_end_cover_primary_color = hr_rackmount_primary_color;

/**
 * 🧢 end_cover
 *
 * Public, the module consumers call. BOSL2 attachable.
 * Closes the top or bottom of a rack between two rackmount adapters: a body across the rack opening
 * with a tongue at each end that slides into an adapter's end cover dock.
 * A neck with the tongue's cross-section joins both tongues through the body.
 * The body keeps TOLERANCE / 2 of clearance toward each dock and toward the rack unit on the inside.
 * Its outer face carries an engraved TOP or BOTTOM.
 * It's printed upright: its front vertical edges and the tongues' free ends are rounded, its outer face chamfers all around,
 * and its inner face chamfers along the front, both ends and the back.
 * The top cover's tongues and neck reach down through the gap fill above the top rack unit, so the cover rests on it.
 *
 * Parameters:
 *   rackwidth (number): The width of the rack in inches.
 *   height_units (number): The adapters' height in standard rack units; the top cover grows by their gap fill height.
 *   type (enum, default=END_COVER_TOP): END_COVER_TOP or END_COVER_BOTTOM.
 *   debug_colors (bool, default=false): Colors the body (blue), the neck (charcoal), the tongues (white) and their grooves (red).
 *   disable_chamfer (bool, default=false): Removes the chamfers.
 *   anchor, spin, orient: BOSL2 attachment, see https://github.com/BelfrySCAD/BOSL2/wiki/attachments.scad
 *
 * Named anchors:
 *   "end_cover_left", "end_cover_right": front center of the left and right dock pocket, pointing FRONT.
 *   They pair with the adapters' "end_cover_top" and "end_cover_bottom" anchors, in both directions:
 *   rackmount_adapter(...) attach("end_cover_top", "end_cover_left") end_cover(...)
 *   end_cover(...) attach("end_cover_right", "end_cover_top") rackmount_adapter(..., side = RIGHT)
 *
 * Produces:
 *   The end cover, its attachment box flush with the docks' front and outer face and the rack unit on the inside.
 */
module end_cover(rackwidth, height_units, type = END_COVER_TOP,
  debug_colors = false, disable_chamfer = false,
  anchor = CENTER, spin = 0, orient = UP) {
  hook_side = type == END_COVER_TOP ? TOP : BOTTOM;
  pocket = get_end_cover_pocket_size(rackwidth);
  dock_height = get_end_cover_dock_height();
  opening = rackwidth * 25.4 - 2 * STD_MOUNT_SURFACE_WIDTH;
  // the top dock sits on the gap fill above the top rack unit; the top cover reaches down to that unit
  gapfill_height = type == END_COVER_TOP ? get_gapfill_top_height(height_units) : 0;

  // nominal box: flush with the docks' front and outer face, reaching the rack unit on the inside
  box_size = [opening, get_connector_cover_depth(), dock_height + gapfill_height];
  pocket_center_x = opening / 2 + pocket.x / 2;
  pocket_center_z = hook_side.z * (box_size.z / 2 - dock_height / 2 - BASE_STRENGTH / 2);
  anchor_y = BASE_STRENGTH - box_size.y / 2;
  // tongues and neck fill the pocket and the gap fill below it, so the cover rests on the rack unit
  tongue_height = pocket.z + gapfill_height;

  // spin keeps the cover upright when attached against the adapters' BACK-pointing anchors
  anchors = [
    named_anchor("end_cover_left", [-pocket_center_x, anchor_y, pocket_center_z], FRONT, spin = 180),
    named_anchor("end_cover_right", [pocket_center_x, anchor_y, pocket_center_z], FRONT, spin = 180),
  ];

  attachable(size = box_size, anchor = anchor, spin = spin, orient = orient, anchors = anchors) {
    // the body keeps TOLERANCE / 2 of clearance toward each dock and toward the rack unit on the inside;
    // printed upright: the front vertical edges round, the back ones stay square so the body covers the neck behind them;
    // the outer face chamfers all around, the inner face from its front edge on, plus the back edge
    up(hook_side.z * TOLERANCE / 4) diff()
      color_this(debug_colors ? HR_BLUE : hr_rackmount_end_cover_primary_color)
        kl_cuboid([box_size.x - TOLERANCE, box_size.y, box_size.z - TOLERANCE / 2],
          rounding = BASE_STRENGTH, rounding_edges = [FRONT + LEFT, FRONT + RIGHT],
          chamfer = disable_chamfer ? 0 : BASE_CHAMFER, chamfer_edges = [hook_side, FRONT - hook_side, BACK - hook_side]) {
          // engraved into the outer face, which faces up when printed, so the two covers can't be mixed up
          tag("remove") attach(hook_side)
            color(debug_colors ? HR_WHITE : hr_rackmount_end_cover_primary_color)
              connector_cover_marking(lines = [type == END_COVER_TOP ? "TOP" : "BOTTOM"], arrow = false);
          // the neck joins both tongues, flush with the body's back and BASE_CHAMFER inside its inner face,
          // so no chamfer exposes it; its outer face lines up with the tongues'
          // align(inside = true) defaults its child to the remove tag; keep makes the neck solid inside the engraving's diff()
          tag("keep") align(-hook_side, BACK, inside = true, overlap = -BASE_CHAMFER, $align_msg = false)
            color_this(debug_colors ? HR_CHARCOAL : hr_rackmount_end_cover_primary_color)
              cuboid([opening, pocket.y, tongue_height - TOLERANCE - BASE_CHAMFER]) {
                // the tongues continue the neck into the docks
                for (side = [LEFT, RIGHT])
                  align(side, BACK + hook_side)
                    end_cover_hook(pocket.x, tongue_height, pocket.y, hook_side = hook_side, cover = true, mirrored = side == RIGHT,
                      color = hr_rackmount_end_cover_primary_color, debug_colors = debug_colors, disable_chamfer = disable_chamfer);
              }
        }
    children();
  }
}
