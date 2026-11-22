// HomeRacker - Rackmount Adapter
//
// Customizable Rackmount adapter for the HomeRacker system.
// Designed to fit standard 10/19-inch (and virtually any inch) rack systems,
// commonly used in server and audio equipment.
//
// MIT License
// Copyright (c) 2025 Patrick Pötz
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

// AI assisted me in closing certain gaps in this model (like creating proper BOSL2 anchors), which are just tedious.
// The entire geometry is still fully my work.

// TODOs
// - proper chamferings
// - debug color and disable chamfer integration for all components
// - Top and bottom closing mechanisms

// Known Limitations (out of scope for now)
// Things I haven't had the motivation or time to implement yet
// - split end covers. Those are not planned yet. They would help print e.g. 19" end covers without the need for extremely large print beds


include <BOSL2/std.scad>
include <../../core/lib/constants.scad>
include <../../sleeve/lib/sleeve.scad>

// rackmount constants
// FYI: this first iteration just assumes M6 cage nuts and bolts.

// Colors
hr_rackmount_primary_color = HR_YELLOW;

// Cage Nut Hole constants (taken from the original Fusion360 design)
hr_rackmount_cage_nut_hole_height = 9.5;  // in mm

// the front part of the cage nut hole
hr_rackmount_cage_nut_hole_front_height = 8.5;  // in mm - a bit smaller than the total height for more "flesh" at the front
hr_rackmount_cage_nut_hole_front_width = 6.5;   // in mm
hr_rackmount_cage_nut_hole_front_depth = 2;     // in mm
hr_rackmount_cage_nut_hole_front_rounding = 3;  // in mm - radius of a M6 screw thread

// the part where the hooks of the cage nut engage
hr_rackmount_cage_nut_hole_mid_width = 13.4;  // in mm - hooks of a cage nut are 14mm
hr_rackmount_cage_nut_hole_mid_depth = 0.6;   // in mm

// the rackside hook part of the cage nut hole
// formed as cylinders left and right at the back of the hole
hr_rackmount_cage_nut_hole_back_radius = 1.5;  // in mm
hr_rackmount_cage_nut_hole_back_width = 12.5;  // in mm

// Markings engraved into the connector-facing side of the connector covers
hr_rackmount_marking_depth = 1;                            // in mm
hr_rackmount_marking_size = 5;                             // in mm - text height
hr_rackmount_marking_line_pitch = 7;                       // in mm
hr_rackmount_marking_arrow_length = 9;                     // in mm
hr_rackmount_marking_arrow_width = 1.2;                    // in mm - shaft width, at least 3 nozzle widths to engrave cleanly
hr_rackmount_marking_font = "Liberation Sans:style=Bold";  // ships with OpenSCAD

// Mount Bridge
// The incline to broaden the bridge to match up with the homeracker sleeve width
mount_bridge_incline = BASE_STRENGTH + TOLERANCE / 2;
mount_bridge_width = BASE_UNIT + mount_bridge_incline;

/**
 * Returns the difference in height between HomeRacker units (multiple of 3 BASE_UNITs)
 * and standard height units for a given number of standard height units.
 * @param height_units The height in standard height units.
 * @return The difference in height in mm.
 */
function get_hr_to_std_height_diff(height_units) =
  let(
    hr_units_per_std_unit = 3,
    hr_height = hr_units_per_std_unit * BASE_UNIT
  )
  (hr_height - STD_UNIT_HEIGHT) * height_units;

/**
 * Returns the number of required HomeRacker units for a given height in standard height units.
 * Note: This setup assumes connectors above and below each rackmount unit.
 *       Therefore we subtract 2 units from the calculated height.
 * @param height_units The height in standard height units.
 * @return The number of HomeRacker units.
 */
function get_hr_units_by_height_units(height_units) =
  ceil(height_units * STD_UNIT_HEIGHT / BASE_UNIT) - 2;

/**
 * Returns the number of required HomeRacker units for a given rack width in inches.
 * They represent the length of the front horizontal support in the rack.
 * @param inches The width of the rack in full inches.
 * @return The number of HomeRacker units.
 */
function get_hr_units_by_inches(inches) =
  let(
    total_rackwidth = inches * 25.4,
    max_intrusion_width = BASE_STRENGTH / 2,
    hr_units = ceil(((total_rackwidth + max_intrusion_width) / BASE_UNIT))
  )
  hr_units;

/**
 * Returns the gap fill for both rackmount adapter sides in mm
 * Enables a truly any-inch adapter to close the gap between standard racks and HomeRacker.
 * @param inches The size of the adapter in full inches.
 * @return The gap fill for both rackmount adapter sides in mm.
 */
function get_adapter_gapfill(inches) =
  let(
    total_rackwidth = inches * 25.4,
    hr_units = get_hr_units_by_inches(inches),
    hr_width = hr_units * BASE_UNIT
  )
  hr_width - total_rackwidth
  ;

/**
 * Returns the total depth of the rackmount cage nut hole.
 * Required for calling panels that need to know their own required depth to place the cage nut hole correctly.
 */
function get_rackmount_cage_nut_hole_depth() =
  hr_rackmount_cage_nut_hole_front_depth
  + hr_rackmount_cage_nut_hole_mid_depth
  + hr_rackmount_cage_nut_hole_back_radius * 2;

/**
 * Rackmount Cage Nut Hole Module
 * Represents the negative to be cutout from a rackmount panel.
 */
module rackmount_cage_nut_hole(debug_colors = false,
  anchor = CENTER, orient = UP, spin = 0) {

  module rackmount_cage_nut_hole_front(anchor = CENTER, orient = UP, spin = 0) {
    depth = hr_rackmount_cage_nut_hole_front_depth + HR_EPSILON;
    attachable(size = [hr_rackmount_cage_nut_hole_front_width, depth, hr_rackmount_cage_nut_hole_front_height], anchor = anchor, orient = orient, spin = spin) {
      color(debug_colors ? HR_YELLOW : hr_rackmount_primary_color)
        cuboid(
          [hr_rackmount_cage_nut_hole_front_width, depth, hr_rackmount_cage_nut_hole_front_height],
          rounding = hr_rackmount_cage_nut_hole_front_rounding, except = [FRONT, BACK]
        );
      children();
    }
  }

  module rackmount_cage_nut_hole_mid(anchor = CENTER, orient = UP, spin = 0) {
    depth = hr_rackmount_cage_nut_hole_mid_depth + HR_EPSILON;
    attachable(size = [hr_rackmount_cage_nut_hole_mid_width, depth, hr_rackmount_cage_nut_hole_height], anchor = anchor, orient = orient, spin = spin) {
      color(debug_colors ? HR_GREEN : hr_rackmount_primary_color)
        cuboid([hr_rackmount_cage_nut_hole_mid_width, depth, hr_rackmount_cage_nut_hole_height]);
      children();
    }
  }

  module rackmount_cage_nut_hole_back(anchor = CENTER, orient = UP, spin = 0) {
    depth = hr_rackmount_cage_nut_hole_back_radius * 2 + HR_EPSILON;
    attachable(size = [hr_rackmount_cage_nut_hole_back_width, depth, hr_rackmount_cage_nut_hole_height], anchor = anchor, orient = orient, spin = spin) {
      color_this(debug_colors ? HR_BLUE : hr_rackmount_primary_color)
        diff()
          cuboid([hr_rackmount_cage_nut_hole_back_width, depth, hr_rackmount_cage_nut_hole_height]) {
            align([LEFT, RIGHT], inside = true, overlap = hr_rackmount_cage_nut_hole_back_radius)
              color(debug_colors ? HR_RED : hr_rackmount_primary_color) tag("remove")
                cylinder(r = hr_rackmount_cage_nut_hole_back_radius, h = hr_rackmount_cage_nut_hole_height + HR_EPSILON);
          }
      children();
    }
  }

  attachable_width = hr_rackmount_cage_nut_hole_mid_width;
  attachable_depth = get_rackmount_cage_nut_hole_depth();
  attachable_height = hr_rackmount_cage_nut_hole_height;

  attachable(size = [attachable_width, attachable_depth, attachable_height], anchor = CENTER, orient = UP, spin = 0) {
    tag_scope("rackmount_cage_nut_hole")
      fwd(hr_rackmount_cage_nut_hole_mid_depth / 2 + hr_rackmount_cage_nut_hole_back_radius)
        rackmount_cage_nut_hole_front() {
          attach(BACK, FRONT, overlap = HR_EPSILON) rackmount_cage_nut_hole_mid() {
            attach(BACK, FRONT, overlap = HR_EPSILON) rackmount_cage_nut_hole_back();
          }
        }
    children();
  }
}

/**
 * Rackmount Cage Nut Module
 * Represents single standard unit rackmount using cage nut holes as mounting points.
 */
module rackmount_cage_nut_single(
  debug_colors = false, disable_chamfer = false,
  anchor = CENTER, orient = UP, spin = 0) {

  attachable_width = STD_MOUNT_SURFACE_WIDTH;
  attachable_depth = get_rackmount_cage_nut_hole_depth();
  attachable_height = STD_UNIT_HEIGHT;
  attachable(
    size = [attachable_width, attachable_depth, attachable_height],
    anchor = anchor, orient = orient, spin = spin) {
    tag_scope("rackmount_cage_nut")
      diff()
        color_this(debug_colors ? HR_WHITE : hr_rackmount_primary_color)
          cuboid([STD_MOUNT_SURFACE_WIDTH, attachable_depth, attachable_height], chamfer = disable_chamfer ? 0 : BASE_CHAMFER, edges = FRONT + RIGHT) {
            tag("remove")
              zcopies(spacing = STD_RACK_BORE_DISTANCE_Z, n = 3)
                rackmount_cage_nut_hole(debug_colors = debug_colors);
          }
    children();
  }
}

/**
 * Rackmount Cage Nut Module (Multiple Units)
 * Represents a stack of standard unit rackmounts using cage nut holes as mounting points.
 */
module rackmount_cage_nut(height_units, debug_colors = false, disable_chamfer = false,
  anchor = CENTER, orient = UP, spin = 0) {

  attachable_width = STD_MOUNT_SURFACE_WIDTH;
  attachable_depth = get_rackmount_cage_nut_hole_depth();
  attachable_height = height_units * STD_UNIT_HEIGHT;
  attachable(
    size = [attachable_width, attachable_depth, attachable_height],
    anchor = anchor, orient = orient, spin = spin) {

    zcopies(spacing = STD_UNIT_HEIGHT, n = height_units)
      rackmount_cage_nut_single(debug_colors = debug_colors, disable_chamfer = disable_chamfer);
    children();
  }
}

/**
 * Returns the depth of the connector cover.
 * Leaves a bit of room between the cover and the connectors.
 */
function get_connector_cover_depth() = BASE_UNIT - BASE_STRENGTH - TOLERANCE / 2;

/**
 * Returns the height of the connector cover, including the BASE_STRENGTH that overlaps into the mount bridge.
 * Adds a tolerance to compensate for the sleeve deviation.
 */
function get_connector_cover_height() = BASE_UNIT + BASE_UNIT / 2 + TOLERANCE / 2 + BASE_STRENGTH;

/**
 * Connector Cover Marking Module
 *
 * Internal, called by connector_cover.
 * Builds the body of an engraved marking: an optional arrow pointing to +Y above centered text lines.
 * The body reaches from z = -hr_rackmount_marking_depth up to just above z = 0, so it cuts cleanly through a face at z = 0.
 *
 * Parameters:
 *   lines (list): Text lines, top to bottom.
 *   arrow (bool): Adds an arrow above the lines.
 *   mirrored (bool): Mirrors the marking along X, to cancel out a mirrored parent so the text still reads correctly.
 */
module connector_cover_marking(lines, arrow, mirrored = false) {
  heights = concat(
    arrow ? [hr_rackmount_marking_arrow_length + hr_rackmount_marking_line_pitch - hr_rackmount_marking_size] : [],
    [for (line = lines) hr_rackmount_marking_line_pitch]
  );
  total_height = sum(heights);
  row_centers = [for (i = idx(heights)) total_height / 2 - cumsum(heights)[i] + heights[i] / 2];

  xscale(mirrored ? -1 : 1) down(hr_rackmount_marking_depth)
    linear_extrude(hr_rackmount_marking_depth + HR_EPSILON) {
      if (arrow)
        back(row_centers[0])
          stroke([[0, -hr_rackmount_marking_arrow_length / 2], [0, hr_rackmount_marking_arrow_length / 2]],
            width = hr_rackmount_marking_arrow_width, endcap2 = "arrow2");
      for (i = idx(lines))
        back(row_centers[i + (arrow ? 1 : 0)])
          text(lines[i], size = hr_rackmount_marking_size, font = hr_rackmount_marking_font, halign = "center", valign = "center");
    }
}

/**
 * Connector Cover Module
 * Prolongs the mount_bridge to cover HomeRacker connectors at top and bottom.
 * Extends exactly into half the height of the adjoining connector,
 * plus BASE_STRENGTH that overlaps into the mount bridge so its chamfers blend into the bridge's.
 * Markings are engraved into the connector-facing side, so the visible side stays clean and the connector still sits flush.
 * @param marking Text lines to engrave, top to bottom.
 * @param marking_arrow Adds an up arrow above the marking lines.
 * @param bridge_side TOP or BOTTOM: the end that overlaps into the mount bridge. Markings center on the rest.
 * @param mirrored Set when a parent mirrors the cover, so the markings still read correctly.
 */
module connector_cover(marking = [], marking_arrow = false, bridge_side = BOTTOM, mirrored = false,
  debug_colors = false, disable_chamfer = false,
  anchor = CENTER, orient = UP, spin = 0) {
  attachable_width = mount_bridge_width;
  attachable_depth = get_connector_cover_depth();
  attachable_height = get_connector_cover_height();

  cutout_depth = attachable_depth - get_rackmount_cage_nut_hole_depth();

  tag_scope("connector_cover")
    attachable(
      size = [attachable_width, attachable_depth, attachable_height],
      anchor = anchor, orient = orient, spin = spin) {
      diff()
        color_this(debug_colors ? HR_BLUE : hr_rackmount_primary_color)
          cuboid([attachable_width, attachable_depth, attachable_height]) {
            if (!disable_chamfer) {
              color_this(debug_colors ? HR_WHITE : hr_rackmount_primary_color)
                tag("remove") edge_mask(edges = [LEFT, TOP + FRONT, BOTTOM + FRONT])
                  chamfer_edge_mask(chamfer = BASE_CHAMFER);
              color_this(debug_colors ? HR_WHITE : hr_rackmount_primary_color)
                tag("remove") corner_mask(corners = [LEFT + TOP + FRONT, LEFT + BOTTOM + FRONT])
                  chamfer_corner_mask(chamfer = BASE_CHAMFER);
            }
            if (marking != [] || marking_arrow)
              tag("remove") attach(BACK) back(-bridge_side.z * BASE_STRENGTH / 2)
                color(debug_colors ? HR_WHITE : hr_rackmount_primary_color) connector_cover_marking(lines = marking, arrow = marking_arrow, mirrored = mirrored);
          }
      children();
    }
}

/**
 * End Cover Dock Module
 * Represents the docking point for the end cover of the rackmount.
 * An end cover is used to cover top or bottom ends of the rackmount for a clean finish.
 * The dock is the insert point where the end cover attaches to the rackmounts on each end.
 * @param width The width of the end cover dock.
 */
END_COVER_TOP = 0;
END_COVER_BOTTOM = 1;

module end_cover_dock(type = END_COVER_TOP, width, debug_colors = false, disable_chamfer = false) {

  attachable_width = width;
  attachable_depth = get_connector_cover_depth();
  attachable_height = BASE_UNIT / 2;

  move_down = (BASE_STRENGTH + HR_EPSILON) / 2 * (type == END_COVER_TOP ? 1 : -1);
  top_or_bottom = type == END_COVER_TOP ? TOP : BOTTOM;
  chamfer_edges = [top_or_bottom + FRONT, top_or_bottom + RIGHT, FRONT + RIGHT];

  tag_scope("end_cover_dock")
    attachable(
      size = [attachable_width, attachable_depth, attachable_height],
      anchor = CENTER, orient = UP, spin = 0) {
      diff()
        color_this(debug_colors ? HR_YELLOW : hr_rackmount_primary_color)
          cuboid([attachable_width, attachable_depth, attachable_height],
            chamfer = disable_chamfer ? 0 : BASE_CHAMFER, edges = chamfer_edges) {
            // cutout for the end cover dock
            cutout_depth = attachable_depth - BASE_STRENGTH + HR_EPSILON;
            tag("remove")
              down(move_down) back(BASE_STRENGTH / 2 + HR_EPSILON / 2)
                color_this(debug_colors ? HR_YELLOW : hr_rackmount_primary_color)
                  cuboid([attachable_width + HR_EPSILON, cutout_depth, attachable_height - BASE_STRENGTH + HR_EPSILON]) {
                    // End Cover Hook
                    hook_strength = 3;
                    tag("keep") left(BASE_STRENGTH) align(top_or_bottom, RIGHT, inside = true)
                      color_this(debug_colors ? HR_GREEN : hr_rackmount_primary_color)
                        cuboid([hook_strength, cutout_depth, hook_strength],
                          rounding = BASE_CHAMFER, edges = [-top_or_bottom + LEFT, -top_or_bottom + RIGHT]);
                  }
          }
      children();
    }
}

/**
 * Rackmount Adapter Module
 * Represents an adapter between standard rackmounts and the HomeRacker system
 * for one side of the rack. The right side is the mirrored left side with readable markings.
 * Use side = RIGHT instead of mirroring the module or the exported part, which would mirror the markings too.
 * @param rackwidth The width of the rack in inches.
 * @param height_units The height of the adapter in standard rack units (1U = 44.45 mm).
 * @param side LEFT or RIGHT: the rack side the adapter mounts on.
 *
 * Named anchors:
 *   "end_cover_top", "end_cover_bottom": inner face of each end cover dock's front wall, centered on its pocket,
 *   pointing BACK through the pocket. Attach an end cover with attach("end_cover_top", FRONT).
 */
module rackmount_adapter(rackwidth, height_units, side = LEFT,
  debug_colors = false, disable_chamfer = false,
  anchor = CENTER, orient = UP, spin = 0) {

  gapfill_width = get_adapter_gapfill(rackwidth) / 2;
  gapfill_depth = get_rackmount_cage_nut_hole_depth();
  gapfill_height = height_units * STD_UNIT_HEIGHT;

  // Warning: this assumes the cage_nut_hole_depth is smaller than a BASE_UNIT (which as of now it is)
  mount_bridge_depth = BASE_UNIT;
  // Due to connectors above and below each rackmount, we need to subract 2 units from the height
  hr_height_units = get_hr_units_by_height_units(height_units);
  // we'll subtract a TOLERANCE to flush fit the sleeve
  mount_bridge_height = hr_height_units * BASE_UNIT - TOLERANCE;

  attachable_width = STD_MOUNT_SURFACE_WIDTH + mount_bridge_width + gapfill_width;
  // the sleeve overlaps BASE_STRENGTH into the bridge, the connector covers stick out above and below it
  attachable_depth = mount_bridge_depth + HR_SLEEVE_DEPTH - BASE_STRENGTH;
  attachable_height = mount_bridge_height + 2 * (get_connector_cover_height() - BASE_STRENGTH);
  // the geometry is built around the mount bridge center; this moves it to the center of the attachment box
  bridge_offset = [(attachable_width - mount_bridge_width) / 2, (attachable_depth - mount_bridge_depth) / 2, 0];

  // the end cover docks span the mount width next to the bridge, their pockets open to the back behind a BASE_STRENGTH front wall
  end_cover_dock_wall = [
    (mount_bridge_width + gapfill_width + STD_MOUNT_SURFACE_WIDTH) / 2 - bridge_offset.x,
    BASE_STRENGTH - mount_bridge_depth / 2 - bridge_offset.y,
    // pocket center below the dock's BASE_STRENGTH roof; docks end flush with the box's top and bottom
    attachable_height / 2 - BASE_STRENGTH / 2 - BASE_UNIT / 4,
  ];

  chamfer_color = debug_colors ? HR_WHITE : hr_rackmount_primary_color;
  assert(side == LEFT || side == RIGHT, "rackmount_adapter: side must be LEFT or RIGHT");
  mirrored = side == RIGHT;
  end_cover_dock_x = end_cover_dock_wall.x * (mirrored ? -1 : 1);
  anchors = [
    named_anchor("end_cover_top", [end_cover_dock_x, end_cover_dock_wall.y, end_cover_dock_wall.z], BACK),
    named_anchor("end_cover_bottom", [end_cover_dock_x, end_cover_dock_wall.y, -end_cover_dock_wall.z], BACK),
  ];

  attachable(
    size = [attachable_width, attachable_depth, attachable_height],
    anchor = anchor, orient = orient, spin = spin, anchors = anchors) {
    // the left side adapter, mirrored for the right side
    xscale(mirrored ? -1 : 1) move(-bridge_offset) diff()
      color_this(debug_colors ? HR_YELLOW : hr_rackmount_primary_color)
        // The Mounting Bridge is the (debug colors) yellow center piece that connects the rackmount to the HomeRacker system.
        cuboid([mount_bridge_width, mount_bridge_depth, mount_bridge_height]) {
          // proper chamfers
          if (!disable_chamfer) {
            color_this(chamfer_color)
              edge_mask(edges = LEFT, except = BACK)
                chamfer_edge_mask(chamfer = BASE_CHAMFER);
          }

          // Connector Covers at top and bottom of the mounting bridge.
          // They chamfer themselves, kept from the bridge's masks.
          // That's why we use the overlap.
          tag("keep") {
            align(TOP, FRONT, overlap = BASE_STRENGTH)
              connector_cover(marking = ["UP"], marking_arrow = true, bridge_side = BOTTOM, mirrored = mirrored,
                debug_colors = debug_colors, disable_chamfer = disable_chamfer);
            align(BOTTOM, FRONT, overlap = BASE_STRENGTH)
              connector_cover(marking = [str(rackwidth, "\""), str(height_units, "U")], bridge_side = TOP, mirrored = mirrored,
                debug_colors = debug_colors, disable_chamfer = disable_chamfer);
          }

          // the gapfill in the middle at the front.
          // The Gapfill is essential to account for differently sized racks.
          // It fills the space between the mounting bridge (HomeRacker standard) and the rackmount itself to ensure "standard" rack alignment.
          // It needs to be aligned downwards to center the gapfill vertically.
          // Additionally to account for the sleeve's smaller size (a sleeve deducts a TOLERANCE to fit between connectors),
          // we shift the gapfill down by half the TOLERANCE to center it vertically.

          down(BASE_UNIT + TOLERANCE / 2)
            align(RIGHT, FRONT + BOTTOM) color_this(debug_colors ? HR_CHARCOAL : hr_rackmount_primary_color)
              cuboid([gapfill_width, gapfill_depth, gapfill_height]) {
                mount_width_total = gapfill_width + STD_MOUNT_SURFACE_WIDTH;
                // lastly the rackmount to the right side
                // needs to be shifted down 1 hr-unit.
                align(RIGHT) rackmount_cage_nut(height_units = height_units, debug_colors = debug_colors, disable_chamfer = disable_chamfer) {
                  align(BOTTOM, RIGHT + FRONT)
                    end_cover_dock(type = END_COVER_BOTTOM, width = mount_width_total, debug_colors = debug_colors, disable_chamfer = disable_chamfer);
                }

                // the gapfill at the top of the rackmount to fill the space up to a full homeracker unit
                gapfill_top_depth = BASE_STRENGTH;
                gapfill_top_height = (BASE_UNIT * 3 - STD_UNIT_HEIGHT) * height_units;
                align(TOP, LEFT + FRONT) color_this(debug_colors ? HR_RED : hr_rackmount_primary_color)
                  cuboid([mount_width_total, gapfill_top_depth, gapfill_top_height],
                    chamfer = disable_chamfer ? 0 : BASE_CHAMFER, edges = [RIGHT + FRONT]) {
                    // attach end cover dock at the top of the gapfill
                    align(TOP, LEFT + FRONT)
                      end_cover_dock(type = END_COVER_TOP, width = mount_width_total, debug_colors = debug_colors, disable_chamfer = disable_chamfer);
                  }
              }

          // an inclined wedge to broaden to fit a homeracker sleeve
          // needs to be shifted by half a BASE_STRENGTH to account
          // for the sleeve overlap
          fwd(BASE_STRENGTH / 2)
            align(RIGHT, BACK) color(debug_colors ? HR_BLUE : hr_rackmount_primary_color)
              cuboid(
                [mount_bridge_incline, mount_bridge_incline, mount_bridge_height]
              ) {
                if (!disable_chamfer) {
                  edge_mask(edges = [FRONT + RIGHT])
                    chamfer_edge_mask(chamfer = mount_bridge_incline);
                  edge_mask(edges = [RIGHT + TOP, RIGHT + BOTTOM])
                    chamfer_edge_mask(chamfer = BASE_CHAMFER);
                }
              }
          // at the back we attach a sleeve for mounting to the HomeRacker system.
          tag("keep")
            align(BACK, LEFT, overlap = BASE_STRENGTH)
              sleeve(length = hr_height_units, debug_colors = debug_colors, disable_chamfer = disable_chamfer);
        }

    children();
  }
}
