// HomeRacker - Crates Library
//
// This file is part of HomeRacker implementation by KellerLab.
// It contains the crates module — rugged, stackable crates with optional
// Gridfinity and HomeRacker compatibility.
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

include <BOSL2/std.scad>
include <../../gridfinity/lib/constants.scad>
include <../../core/lib/constants.scad>

KL_CRATE_WALL_STRENGTH = 1;
KL_CRATE_BOTTOM_STRENGTH = 2;
KL_CRATE_RIB_DEPTH = 4;
KL_CRATE_RIB_STRENGTH = 2; // the actual strength is calculated by depth + strength*2 as we need 45° chamfers

KL_CRATE_GF_TOLERANCE = 0.2;

// The standard Gridfinity baseplate corner radius is GRIDFINITY_BP_TOP_PART_ROUNDING (4mm).
// We add tolerance so a baseplate or bin can fit inside effortlessly.
KL_CRATE_CORNER_INNER_RADIUS = GRIDFINITY_BP_TOP_PART_ROUNDING + KL_CRATE_GF_TOLERANCE / 2;


KL_CRATE_RIB_TYPE_BOTTOM = 0;
KL_CRATE_RIB_TYPE_MID = 1;
KL_CRATE_RIB_TYPE_TOP = 2;

KL_CRATE_PRIMARY_COLOR = HR_CHARCOAL;
KL_CRATE_SECONDARY_COLOR = HR_YELLOW;

module horizontal_rib_profile(
  width_inner=GRIDFINITY_BASE_UNIT, depth_inner=GRIDFINITY_BASE_UNIT,
  rib_type = KL_CRATE_RIB_TYPE_MID,
  anchor=CENTER, spin=0, orient=UP,
  debug_colors=false, chamfer_enabled=true
  ) {

  chamfer_edges = rib_type == 0 ? [TOP] : rib_type == 1 ? [TOP, BOTTOM] : [BOTTOM];
  rib_height_multiplier = rib_type == 1 ? 2 : 1;


  width = width_inner + (KL_CRATE_RIB_DEPTH) * 2;
  depth = depth_inner + (KL_CRATE_RIB_DEPTH) * 2;
  height = KL_CRATE_RIB_DEPTH * rib_height_multiplier + KL_CRATE_RIB_STRENGTH;

  radius = KL_CRATE_CORNER_INNER_RADIUS + KL_CRATE_RIB_DEPTH;

  tag_scope("horizontal_rib_profile")
  attachable(anchor, spin, orient, size=[width, depth, height]) {
    diff() color_this(debug_colors ? HR_GREEN : KL_CRATE_SECONDARY_COLOR)
    cuboid([width, depth, height],rounding=radius,except=[TOP,BOTTOM]){

      // chamfering
      tag("remove") color(debug_colors ? HR_BLUE : KL_CRATE_SECONDARY_COLOR) edge_profile(chamfer_edges) mask2d_chamfer(KL_CRATE_RIB_DEPTH);
      tag("remove") color(debug_colors ? HR_GREEN : KL_CRATE_SECONDARY_COLOR) corner_profile(chamfer_edges, r=radius) mask2d_chamfer(KL_CRATE_RIB_DEPTH);

      // classic bottom chamfer
      if(rib_type == KL_CRATE_RIB_TYPE_BOTTOM && chamfer_enabled){
        tag("remove") color(debug_colors ? HR_BLUE : KL_CRATE_SECONDARY_COLOR) edge_profile(BOTTOM) mask2d_chamfer(1);
        tag("remove") color(debug_colors ? HR_GREEN : KL_CRATE_SECONDARY_COLOR) corner_profile(BOTTOM, r=radius) mask2d_chamfer(1);
      }

      // cutout inside
      tag("remove")
      align(TOP,inside=true)
        color_this(debug_colors ? HR_GREEN : KL_CRATE_SECONDARY_COLOR)
        cuboid([width_inner,depth_inner,height+HR_EPSILON],rounding=KL_CRATE_CORNER_INNER_RADIUS,except=[TOP,BOTTOM]);
    }
    children();
  }

}

module crate_naked(width_inner=GRIDFINITY_BASE_UNIT, depth_inner=GRIDFINITY_BASE_UNIT, height_inner=GRIDFINITY_BASE_UNIT,
  anchor=CENTER, spin=0, orient=UP,
  debug_colors=false, chamfer_enabled=true
  ){

  _outer_width = width_inner + (KL_CRATE_WALL_STRENGTH * 2);
  _outer_depth = depth_inner + (KL_CRATE_WALL_STRENGTH * 2);
  _outer_height = height_inner + KL_CRATE_BOTTOM_STRENGTH;
  _outer_rounding = KL_CRATE_CORNER_INNER_RADIUS + KL_CRATE_WALL_STRENGTH;

  tag_scope("crate_naked")
  attachable(anchor, spin, orient, size=[_outer_width, _outer_depth, _outer_height]) {
    diff()
    cuboid([_outer_width, _outer_depth, _outer_height],rounding=_outer_rounding,except=[TOP,BOTTOM]) {
      align(TOP,inside=true,overlap=HR_EPSILON)
        color_this(debug_colors ? HR_BLUE : KL_CRATE_PRIMARY_COLOR)
        cuboid([width_inner, depth_inner, height_inner],rounding=KL_CRATE_CORNER_INNER_RADIUS,except=[TOP,BOTTOM]);
    }
    children();
  }

}

/*
Calculates the number of ribs (excluding bottom and top) based on the height and divider.

Example:
  height = 42, divider = 42 => 0 => bottom + top (are always there)
  height = 10, divider = 42 => 0 => bottom + top (are always there)
  height = 84, divider = 42 => 1 => bottom + top + mid
  height = 126, divider = 42 => floor(126 / 42) - 1 = 2 => bottom + top + 2 * mid
*/
function get_rib_mid_count_by_divider(height, divider) =
  height*2 < divider ? 0 :
    floor(height / divider) - 1;

/*
calculates the z-position of the midribs
example:
  height = 84, count = 1, position = 0
  z = 84 / (1 + 1) * (0 + 1) = 42;

  height = 126, count = 2, position = 1
  z = 126 / (2 + 1) * (1 + 1) = 126 / 3 * 2 = 42 * 2 = 84;

  height = 150, count = 2, position = 1
  z = 150 / (2 + 1) * (1 + 1) = 150 / 3 * 2 = 50 * 2 = 100;
*/
function get_rib_mid_z_by_count(height, count, position) =
  height / (count + 1) * (position + 1);

// Main module for the crate
module crate(
  width_inner=GRIDFINITY_BASE_UNIT, depth_inner=GRIDFINITY_BASE_UNIT, height_inner=GRIDFINITY_BASE_UNIT,
  horizontal_rib_divider=42,
  debug_colors=false,chamfer_enabled=true
  ) {

  // mid rib count
  rib_count = get_rib_mid_count_by_divider(height_inner, horizontal_rib_divider);
  echo("rib_count: ", rib_count);

  color_this(debug_colors ? HR_YELLOW : KL_CRATE_PRIMARY_COLOR)
  diff("crate_naked")
  crate_naked(width_inner, depth_inner, height_inner) {
    // Bottom rib
    align(BOTTOM,inside=true)
      horizontal_rib_profile(width_inner,depth_inner,KL_CRATE_RIB_TYPE_BOTTOM,debug_colors=debug_colors,chamfer_enabled=chamfer_enabled);

    // Top rib
    align(TOP,inside=true, overlap=-HR_EPSILON)
      horizontal_rib_profile(width_inner,depth_inner,KL_CRATE_RIB_TYPE_TOP,debug_colors=debug_colors,chamfer_enabled=chamfer_enabled);

    // Mid ribs

    for (i = [0:rib_count-1]) {
      z = get_rib_mid_z_by_count(height_inner, rib_count, i);
      echo("rib z-position: ", z, " for position ", i)
      align(BOTTOM,inside=true,overlap=-z) {
        horizontal_rib_profile(width_inner,depth_inner,KL_CRATE_RIB_TYPE_MID,debug_colors=debug_colors,chamfer_enabled=chamfer_enabled);
      }
    }

  }
}
