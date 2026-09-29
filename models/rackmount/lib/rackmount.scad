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

// This piece of code is (so far) purely HI-generated. No AI involved yet.

include <BOSL2/std.scad>
include <../../core/lib/constants.scad>
include <../../sleeve/lib/sleeve.scad>

/* [General] */
// Width of the rack in full inches
inches = 10;       // [2:1:20]
height_units = 1;  // [1:1:10]

/* [Debug] */
debug_colors = false;
disable_chamfer = false;

/* [Hidden] */
$fn = 100;
// rackmount constants
// FYI: this first iteration just assumes M6 cage nuts and bolts.

// Colors
hr_rackmount_primary_color = HR_YELLOW;
hr_rackmount_secondary_color = HR_CHARCOAL;

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
      color(debug_colors ? HR_YELLOW : hr_rackmount_secondary_color)
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
      color(debug_colors ? HR_GREEN : hr_rackmount_secondary_color)
        cuboid([hr_rackmount_cage_nut_hole_mid_width, depth, hr_rackmount_cage_nut_hole_height]);
      children();
    }
  }

  module rackmount_cage_nut_hole_back(anchor = CENTER, orient = UP, spin = 0) {
    depth = hr_rackmount_cage_nut_hole_back_radius * 2 + HR_EPSILON;
    attachable(size = [hr_rackmount_cage_nut_hole_back_width, depth, hr_rackmount_cage_nut_hole_height], anchor = anchor, orient = orient, spin = spin) {
      color_this(debug_colors ? HR_BLUE : hr_rackmount_secondary_color)
        diff()
          cuboid([hr_rackmount_cage_nut_hole_back_width, depth, hr_rackmount_cage_nut_hole_height]) {
            align([LEFT, RIGHT], inside = true, overlap = hr_rackmount_cage_nut_hole_back_radius)
              color(debug_colors ? HR_RED : hr_rackmount_secondary_color) tag("remove")
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
  debug_colors = false,
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
          cuboid([STD_MOUNT_SURFACE_WIDTH, attachable_depth, attachable_height]) {
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
module rackmount_cage_nut(height_units, debug_colors = false,
  anchor = CENTER, orient = UP, spin = 0) {

  attachable_width = STD_MOUNT_SURFACE_WIDTH;
  attachable_depth = get_rackmount_cage_nut_hole_depth();
  attachable_height = height_units * STD_UNIT_HEIGHT;
  attachable(
    size = [attachable_width, attachable_depth, attachable_height],
    anchor = anchor, orient = orient, spin = spin) {

    zcopies(spacing = STD_UNIT_HEIGHT, n = height_units)
      rackmount_cage_nut_single(debug_colors = debug_colors);
    children();
  }
}

/**
 * Rackmount Adapter Module
 * Represents an adapter between standard rackmounts and the HomeRacker system
 * produces only one adapter for the left side of the rack.
 * If you need an adapter for the right side, you will need to mirror this module.
 * @param rackwidth The width of the rack in inches.
 * @param height_units The height of the adapter in standard rack units (1U = 44.45 mm).
 *
 */
module rackmount_adapter(rackwidth, height_units,
  anchor = CENTER, orient = UP, spin = 0) {

  gapfill_width = get_adapter_gapfill(rackwidth) / 2;
  gapfill_depth = get_rackmount_cage_nut_hole_depth();

  mount_bridge_incline = BASE_STRENGTH + TOLERANCE / 2;

  mount_bridge_width = BASE_UNIT + mount_bridge_incline;
  // Warning: this assumes the cage_nut_hole_depth is smaller than a BASE_UNIT (which as of now it is)
  mount_bridge_depth = BASE_UNIT;
  // Due to connectors above and below each rackmount, we need to subract 2 units from the height
  hr_height_units = get_hr_units_by_height_units(height_units);
  // we'll subtract a TOLERANCE to flush fit the sleeve
  mount_bridge_height = hr_height_units * BASE_UNIT - TOLERANCE;

  attachable_width = STD_MOUNT_SURFACE_WIDTH + mount_bridge_width + gapfill_width;
  attachable_depth = mount_bridge_depth;
  attachable_height = mount_bridge_height;

  attachable(
    size = [attachable_width, attachable_depth, attachable_height],
    anchor = anchor, orient = orient, spin = spin) {
    // start at the left side with the mounting bridge
    diff()
      color_this(debug_colors ? HR_YELLOW : hr_rackmount_primary_color)
        cuboid([mount_bridge_width, mount_bridge_depth, mount_bridge_height]) {
          // proper chamfers
          corner_mask(corners = [BACK + TOP + LEFT, BACK + BOTTOM + LEFT])
            chamfer_corner_mask(chamfer = BASE_CHAMFER);

          // the gapfill in the middle at the front.
          align(RIGHT, FRONT) color_this(debug_colors ? HR_CHARCOAL : hr_rackmount_primary_color)
            cuboid([gapfill_width, gapfill_depth, mount_bridge_height]) {
              // lastly the rackmount to the right side
              // needs to be shifted down 1 hr-unit.
              down(BASE_UNIT)
                align(RIGHT, BOTTOM) rackmount_cage_nut(height_units = height_units, debug_colors = debug_colors);
            }
          // an inclined wedge to broaden to fit a homeracker sleeve
          // needs to be shifted by half a BASE_STRENGTH to account
          // for the sleeve overlap
          fwd(BASE_STRENGTH / 2)
            align(RIGHT, BACK) color(debug_colors ? HR_BLUE : hr_rackmount_primary_color)

              cuboid(
                [mount_bridge_incline, mount_bridge_incline, mount_bridge_height]
              ) {
                edge_mask(edges = [FRONT + RIGHT])
                  chamfer_edge_mask(chamfer = mount_bridge_incline);
                edge_mask(edges = [RIGHT + TOP, RIGHT + BOTTOM])
                  chamfer_edge_mask(chamfer = BASE_CHAMFER);
              }
          // at the back we attach a sleeve for mounting to the HomeRacker system.
          tag("keep")
            align(BACK, LEFT, overlap = BASE_STRENGTH)
              sleeve(length = hr_height_units, debug_colors = debug_colors, disable_chamfer = disable_chamfer);
        }

    children();
  }
}

rackmount_adapter(rackwidth = inches, height_units = height_units)
  // show_anchors()
  ;

echo("inches: ", inches);
echo("mm: ", inches * 25.4);

echo("hr units: ", get_hr_units_by_inches(inches));
echo("gapfill: ", get_adapter_gapfill(inches));
echo("hr to std height diff: ", get_hr_to_std_height_diff(height_units));


// if (!disable_chamfer)
//   color_this(debug_colors ? HR_CHARCOAL : hr_rackmount_primary_color)
//     edge_mask(edges = [FRONT, RIGHT], except = LEFT) chamfer_edge_mask(chamfer = BASE_CHAMFER)
