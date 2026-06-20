// HomeRacker - Panel Library
//
// This file is part of HomeRacker implementation by KellerLab.
// It contains the panel module — a plain mounting panel without cutouts that fits
// into the HomeRacker scaffold system. Panels can be used as-is or as a base for
// custom cutouts (e.g. keystone jacks, switches, displays).
//
// Two panel types are supported:
// - Inter-Fit: Inset panel for a flush fit between support bars. Flexible — each
//   panel can be removed independently without affecting others.
// - Full Cover: Overlap panel that covers supports and connectors for a clean look.
//   Less flexible as it must be integrated during scaffold assembly.
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

HR_PANEL_TYPE_INTERFIT = 1;
HR_PANEL_TYPE_FULLCOVER = 2;

HR_PANEL_PRIMARY_COLOR = HR_YELLOW;
HR_PANEL_SECONDARY_COLOR = HR_CHARCOAL;

HR_PANEL_CORNER_MOUNT_SIDE_LENGTH = BASE_UNIT - BASE_STRENGTH;

function get_panel_mount_height(panel_type = HR_PANEL_TYPE_INTERFIT) =
  BASE_UNIT + BASE_STRENGTH * (panel_type == HR_PANEL_TYPE_INTERFIT ? 0 : 1) + TOLERANCE;

function get_lockpin_hole_offset_vertical(panel_type = HR_PANEL_TYPE_INTERFIT) =
  (panel_type == HR_PANEL_TYPE_INTERFIT ? BASE_STRENGTH / 2 : 0)
  - BASE_STRENGTH/2
  - TOLERANCE/2;

/** Panel Lockpin Hole — subtracted from mount plates to create the square hole a lockpin slides into.
Includes an optional chamfer on the insertion side for easier pin alignment.
This is the shallow panel-side passthrough; distinct from the core lockpin_hole(depth=...) reusable cavity.
*/
module panel_lockpin_hole(anchor=CENTER, spin=0, orient=UP, debug_colors=false, chamfer_enabled=false) {

  lockpin_hole_dimensions = [LOCKPIN_HOLE_SIDE_LENGTH, BASE_STRENGTH, LOCKPIN_HOLE_SIDE_LENGTH];
  lockpin_chamfer_dimensions = [LOCKPIN_HOLE_SIDE_LENGTH + LOCKPIN_HOLE_CHAMFER*2, LOCKPIN_HOLE_CHAMFER, LOCKPIN_HOLE_SIDE_LENGTH + LOCKPIN_HOLE_CHAMFER*2];
  attachable(anchor, spin, orient,size=lockpin_hole_dimensions) {
    color(debug_colors ? HR_WHITE : HR_PANEL_PRIMARY_COLOR)
    cuboid(lockpin_hole_dimensions){
      if(chamfer_enabled) align(FRONT, inside=true) cuboid(lockpin_chamfer_dimensions, chamfer=LOCKPIN_HOLE_CHAMFER, edges=BACK);
    }
    children();
  }
}

/** Connector Mount Plate
Meant to be combined with another connector mount plate at the front left to form a corner mount.
Chamfers are already oriented that way
*/
module connector_mount_plate(panel_type=HR_PANEL_TYPE_INTERFIT, anchor=CENTER, spin=0, orient=UP, debug_colors=false,chamfer_enabled=false,inner_chamfer=false,full=true) {

  plate_height = full ? get_panel_mount_height(panel_type) : BASE_STRENGTH;
  attachable_dimensions = [HR_PANEL_CORNER_MOUNT_SIDE_LENGTH, BASE_STRENGTH, plate_height];
  lockpin_hole_offset_horizontal = (BASE_STRENGTH+TOLERANCE)/2;
  lockpin_hole_offset_vertical = get_lockpin_hole_offset_vertical(panel_type);

  chamfer_size = chamfer_enabled ? BASE_CHAMFER : 0;
  chamfer_edges = inner_chamfer ? [BACK+TOP, BACK+LEFT, LEFT+TOP, RIGHT+TOP] : [BACK+TOP, BACK+LEFT, LEFT+TOP];

  attachable(anchor, spin, orient,size=attachable_dimensions) {
    color_this(debug_colors ? HR_RED : HR_PANEL_PRIMARY_COLOR)
    diff()
    cuboid([HR_PANEL_CORNER_MOUNT_SIDE_LENGTH, BASE_STRENGTH, plate_height], chamfer=chamfer_size, edges=chamfer_edges){
      if(full) {
        down(lockpin_hole_offset_vertical) left(lockpin_hole_offset_horizontal)
        attach(FRONT,FRONT, inside=true)
        tag("remove") panel_lockpin_hole(debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
      }
      if(inner_chamfer && full) {
        inner_chamfer_length = plate_height - BASE_CHAMFER;
        tag("remove")
        edge_mask(RIGHT+BACK)
          up(BASE_CHAMFER/2)
          chamfer_edge_mask(l=inner_chamfer_length, chamfer=BASE_CHAMFER);
      }
    }
    children();
  }
}

/** Support Mount Plate for direct support bar contact
Provides a protrusion (bottom plate + wall + bridges) that rests directly on a support bar.
Only applicable if units > 2, otherwise the corner mounts already provide enough lockpin holes.
Oriented per default for mounting on the left side (Y-span, X-protrusion).
Use spin=90/-90 for horizontal placement (X-span, Y-protrusion).
*/
module support_mount_plate(panel_type=HR_PANEL_TYPE_INTERFIT, units, anchor=CENTER, spin=0, orient=UP, debug_colors=false,chamfer_enabled=false,mirrored=false) {
  assert(units > 2, "Support mount plate is only needed for panels larger than 2 units");

  net_units = units - 2;

  bottom_plate_width = BASE_STRENGTH*2 + TOLERANCE/2;
  bottom_plate_depth = BASE_UNIT * net_units;
  bottom_plate_height = BASE_STRENGTH;

  wall_width = BASE_STRENGTH;
  wall_depth = bottom_plate_depth;
  wall_height = get_panel_mount_height(panel_type);

  bridge_width = BASE_STRENGTH;
  bridge_depth = BASE_STRENGTH;
  bridge_height = wall_height;
  bridge_dimensions = [bridge_width, bridge_depth, bridge_height];
  gap_filler_dimensions = [BASE_STRENGTH, TOLERANCE/2, wall_height];

  attachable_dimensions = [bottom_plate_width, bottom_plate_depth, bottom_plate_height+wall_height];

  lockpin_hole_offset_vertical = get_lockpin_hole_offset_vertical(panel_type);

  attachable(anchor, spin, orient,size=attachable_dimensions) {
    mirror([mirrored ? 1 : 0, 0, 0])
    down((bottom_plate_height+wall_height)/2 - BASE_STRENGTH/2)
    color_this(debug_colors ? HR_GREEN : HR_PANEL_PRIMARY_COLOR)
    cuboid([bottom_plate_width, bottom_plate_depth, bottom_plate_height],chamfer=chamfer_enabled ? BASE_CHAMFER : 0,edges=[BOTTOM,LEFT],except=TOP){
      align(TOP,LEFT) color_this(debug_colors ? HR_GREEN : HR_PANEL_PRIMARY_COLOR) diff() cuboid([wall_width, wall_depth, wall_height],chamfer=chamfer_enabled ? BASE_CHAMFER : 0,edges=[LEFT,TOP],except=[BOTTOM,RIGHT]){
        down(lockpin_hole_offset_vertical)
        attach(LEFT,BACK,inside=true)
        xcopies(spacing=BASE_UNIT, n=net_units) panel_lockpin_hole(debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
      }
      color(debug_colors ? HR_GREEN : HR_PANEL_PRIMARY_COLOR)
      align(TOP,RIGHT+BACK) diff() cuboid(bridge_dimensions) {
        if(chamfer_enabled) tag("remove") corner_mask([TOP+BACK+LEFT]) chamfer_corner_mask(chamfer=BASE_CHAMFER/2);
        align(BACK,TOP+RIGHT) cuboid(gap_filler_dimensions, chamfer=chamfer_enabled ? BASE_CHAMFER : 0, edges=TOP+LEFT);
        attach(LEFT,BACK) color_this(debug_colors ? HR_GREEN : HR_PANEL_PRIMARY_COLOR) cuboid(gap_filler_dimensions, chamfer=chamfer_enabled ? BASE_CHAMFER : 0, edges=TOP+LEFT);
      }
      color(debug_colors ? HR_GREEN : HR_PANEL_PRIMARY_COLOR)
      align(TOP,RIGHT+FRONT) diff() cuboid(bridge_dimensions) {
        if(chamfer_enabled) tag("remove") corner_mask([TOP+FWD+LEFT]) chamfer_corner_mask(chamfer=BASE_CHAMFER/2);
        align(FRONT,TOP+RIGHT) cuboid(gap_filler_dimensions, chamfer=chamfer_enabled ? BASE_CHAMFER : 0, edges=TOP+LEFT);
        attach(LEFT,FRONT) color_this(debug_colors ? HR_GREEN : HR_PANEL_PRIMARY_COLOR) cuboid(gap_filler_dimensions, chamfer=chamfer_enabled ? BASE_CHAMFER : 0, edges=TOP+LEFT);
      }
    }
    children();
  }
}

/** Mounting Surface for a single connector corner.
Combines two connector_mount_plates at 90° to form an L-shaped corner bracket.
When full=true, provides full-height lockpin engagement. When full=false,
produces a contour-only corner at BASE_STRENGTH height (no lockpin holes).
*/
module mount_corner(panel_type=HR_PANEL_TYPE_INTERFIT, anchor=CENTER, spin=0, orient=UP, debug_colors=false,chamfer_enabled=false,inner_chamfer_primary=false,inner_chamfer_secondary=false,full=true) {
  corner_height = full ? get_panel_mount_height(panel_type) : BASE_STRENGTH;
  attachable_dimensions = [HR_PANEL_CORNER_MOUNT_SIDE_LENGTH, HR_PANEL_CORNER_MOUNT_SIDE_LENGTH, corner_height];
  attachable(anchor, spin, orient,size=attachable_dimensions) {
    back(HR_PANEL_CORNER_MOUNT_SIDE_LENGTH/2-BASE_STRENGTH/2)
    connector_mount_plate(panel_type=panel_type, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled, inner_chamfer=inner_chamfer_primary, full=full){
      align(BACK,LEFT) mirror([0,1,0]) connector_mount_plate(panel_type=panel_type, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled, inner_chamfer=inner_chamfer_secondary, spin=90, full=full){
      }
    }
    children();
  }
}

/** 📐 Panel — main API module.
Creates a mounting panel for the HomeRacker scaffold system.
Base plate with corner mounts on all four corners, plus per-side mount surfaces
for panels larger than 2×2 units. Full Cover panels get an additional overlap
base plate underneath.

Parameters:
  units_x            (int)   Panel width in HR units (min 2).
  units_y            (int)   Panel height in HR units (min 2).
  panel_type         (int)   1 = Inter-Fit, 2 = Full Cover.
  panel_clearance    (float) Full Cover only — gap between adjacent panels (mm).
  corner_mounts      (bool)  Full-height corners with lockpin holes (false = contour only).
  mount_north        (bool)  Mount plate on north (back) edge.
  mount_south        (bool)  Mount plate on south (front) edge.
  mount_east         (bool)  Mount plate on east (right) edge.
  mount_west         (bool)  Mount plate on west (left) edge.
  debug_colors       (bool)  Distinct HR_ colors per section.
  chamfer_enabled    (bool)  Apply chamfers to edges.
*/
module panel(units_x, units_y, panel_type = HR_PANEL_TYPE_INTERFIT, panel_clearance = 0.0,
  corner_mounts=true, mount_north=true, mount_south=true, mount_east=true, mount_west=true,
  anchor=CENTER, spin=0, orient=UP, debug_colors=false,chamfer_enabled=true
  ) {
  assert(panel_type == HR_PANEL_TYPE_INTERFIT || panel_type == HR_PANEL_TYPE_FULLCOVER, "Invalid panel type");
  assert(units_x >= 2 && units_y >= 2, "Units must be at least 2 in both dimensions");

  interfit_deduction = (2 * BASE_STRENGTH + TOLERANCE);

  panel_width = units_x * BASE_UNIT - interfit_deduction;
  panel_depth = units_y * BASE_UNIT - interfit_deduction;
  attachable_height = BASE_STRENGTH + get_panel_mount_height(panel_type);


  attachable_width = panel_width + (units_y > 2 ? BASE_STRENGTH * 2 : 0);
  attachable_depth = panel_depth + (units_x > 2 ? BASE_STRENGTH * 2 : 0);

  attachable_dimensions = [attachable_width, attachable_depth, attachable_height];

  fullcover_addition = BASE_UNIT - panel_clearance;
  full_cover_width = units_x * BASE_UNIT + fullcover_addition;
  full_cover_depth = units_y * BASE_UNIT + fullcover_addition;

  attachable(anchor, spin, orient, size=attachable_dimensions) {
    down(attachable_height/2-BASE_STRENGTH/2)
    color_this(debug_colors ? HR_BLUE : HR_PANEL_PRIMARY_COLOR)
    cuboid([panel_width, panel_depth, BASE_STRENGTH],chamfer=chamfer_enabled ? BASE_CHAMFER : 0, except=TOP){
      // Corner Mounts
      wall_chamfer_north = panel_type == HR_PANEL_TYPE_FULLCOVER && units_x > 2 && !mount_north;
      wall_chamfer_south = panel_type == HR_PANEL_TYPE_FULLCOVER && units_x > 2 && !mount_south;
      wall_chamfer_west = panel_type == HR_PANEL_TYPE_FULLCOVER && units_y > 2 && !mount_west;
      wall_chamfer_east = panel_type == HR_PANEL_TYPE_FULLCOVER && units_y > 2 && !mount_east;
      align(TOP,LEFT+BACK) mount_corner(panel_type=panel_type, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled, inner_chamfer_primary=wall_chamfer_north, inner_chamfer_secondary=wall_chamfer_west, full=corner_mounts);
      align(TOP,LEFT+FRONT) mount_corner(panel_type=panel_type, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled, spin=90, inner_chamfer_primary=wall_chamfer_west, inner_chamfer_secondary=wall_chamfer_south, full=corner_mounts);
      align(TOP,RIGHT+FRONT) mount_corner(panel_type=panel_type, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled, spin=180, inner_chamfer_primary=wall_chamfer_south, inner_chamfer_secondary=wall_chamfer_east, full=corner_mounts);
      align(TOP,RIGHT+BACK) mount_corner(panel_type=panel_type, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled, spin=270, inner_chamfer_primary=wall_chamfer_east, inner_chamfer_secondary=wall_chamfer_north, full=corner_mounts);
      // North/South mount surfaces (horizontal edges, only when units_x > 2)
      wall_color = debug_colors ? HR_GREEN : HR_PANEL_PRIMARY_COLOR;
      wall_chamfer_size = chamfer_enabled ? BASE_CHAMFER : 0;
      wall_height = panel_type == HR_PANEL_TYPE_INTERFIT ? get_panel_mount_height(panel_type) : BASE_STRENGTH;
      fullcover_wall_ext = panel_type == HR_PANEL_TYPE_FULLCOVER ? 2 * BASE_CHAMFER : 0;
      lockpin_hole_offset_vertical = get_lockpin_hole_offset_vertical(panel_type);
      if(units_x > 2) {
        net_units_x = units_x - 2;
        if(mount_north) {
          align(BACK,BOTTOM,overlap=BASE_STRENGTH) support_mount_plate(panel_type=panel_type, units=units_x, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled, spin=-90);
        } else {
          h_wall = [(units_x - 2) * BASE_UNIT + fullcover_wall_ext, BASE_STRENGTH, wall_height];
          color_this(wall_color) align(TOP,BACK) diff() cuboid(h_wall, chamfer=wall_chamfer_size, edges=[BACK+TOP]){
            if(panel_type == HR_PANEL_TYPE_INTERFIT)
              tag("remove") down(lockpin_hole_offset_vertical) attach(BACK,BACK,inside=true)
                xcopies(spacing=BASE_UNIT, n=net_units_x) panel_lockpin_hole(debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
          }
        }
        if(mount_south) {
          align(FRONT,BOTTOM,overlap=BASE_STRENGTH) support_mount_plate(panel_type=panel_type, units=units_x, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled, spin=90);
        } else {
          h_wall = [(units_x - 2) * BASE_UNIT + fullcover_wall_ext, BASE_STRENGTH, wall_height];
          color_this(wall_color) align(TOP,FRONT) diff() cuboid(h_wall, chamfer=wall_chamfer_size, edges=[TOP+FRONT]){
            if(panel_type == HR_PANEL_TYPE_INTERFIT)
              tag("remove") down(lockpin_hole_offset_vertical) attach(FRONT,BACK,inside=true)
                xcopies(spacing=BASE_UNIT, n=net_units_x) panel_lockpin_hole(debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
          }
        }
      }
      // East/West mount surfaces (vertical edges, only when units_y > 2)
      if(units_y > 2) {
        net_units_y = units_y - 2;
        if(mount_west) {
          align(LEFT,BOTTOM,overlap=BASE_STRENGTH) support_mount_plate(panel_type=panel_type, units=units_y, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
        } else {
          v_wall = [BASE_STRENGTH, (units_y - 2) * BASE_UNIT + fullcover_wall_ext, wall_height];
          color_this(wall_color) align(TOP,LEFT) diff() cuboid(v_wall, chamfer=wall_chamfer_size, edges=[LEFT+TOP]){
            if(panel_type == HR_PANEL_TYPE_INTERFIT)
              tag("remove") down(lockpin_hole_offset_vertical) attach(LEFT,BACK,inside=true)
                xcopies(spacing=BASE_UNIT, n=net_units_y) panel_lockpin_hole(debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
          }
        }
        if(mount_east) {
          align(RIGHT,BOTTOM,overlap=BASE_STRENGTH) support_mount_plate(panel_type=panel_type, units=units_y, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled, mirrored=true);
        } else {
          v_wall = [BASE_STRENGTH, (units_y - 2) * BASE_UNIT + fullcover_wall_ext, wall_height];
          color_this(wall_color) align(TOP,RIGHT) diff() cuboid(v_wall, chamfer=wall_chamfer_size, edges=[TOP+RIGHT]){
            if(panel_type == HR_PANEL_TYPE_INTERFIT)
              tag("remove") down(lockpin_hole_offset_vertical) attach(RIGHT,BACK,inside=true)
                xcopies(spacing=BASE_UNIT, n=net_units_y) panel_lockpin_hole(debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
          }
        }
      }
      // Add full cover overlaps if needed
      if(panel_type == HR_PANEL_TYPE_FULLCOVER) {
        full_cover_dimensions = [full_cover_width, full_cover_depth, BASE_STRENGTH];
        color_this(debug_colors ? HR_RED : HR_PANEL_PRIMARY_COLOR)
        attach(BOTTOM,BOTTOM,inside=true) cuboid(full_cover_dimensions, chamfer=chamfer_enabled ? BASE_CHAMFER : 0, edges=[BOTTOM]);
      }
    }
    children();
  }
}
