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

KL_CRATE_BOTTOM_STRENGTH_DEFAULT = 1;
KL_CRATE_WALL_STRENGTH = 1.2;
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

function get_horizontal_rib_height(rib_type) =
  KL_CRATE_RIB_DEPTH * 2 + KL_CRATE_RIB_STRENGTH;

module horizontal_rib_profile(
  width_inner = GRIDFINITY_BASE_UNIT,
  depth_inner = GRIDFINITY_BASE_UNIT,
  rib_type = KL_CRATE_RIB_TYPE_MID,
  anchor = CENTER,
  spin = 0,
  orient = UP,
  debug_colors = false,
  chamfer_enabled = true
) {

  chamfer_edges = rib_type == 0 ? [TOP] : rib_type == 1 ? [TOP, BOTTOM] : [BOTTOM];

  width = width_inner + (KL_CRATE_RIB_DEPTH) * 2;
  depth = depth_inner + (KL_CRATE_RIB_DEPTH) * 2;
  height = get_horizontal_rib_height(rib_type);

  radius = KL_CRATE_CORNER_INNER_RADIUS + KL_CRATE_RIB_DEPTH;

  tag_scope("horizontal_rib_profile")
  attachable(anchor, spin, orient, size=[width, depth, height]) {
    diff() color_this(debug_colors ? HR_GREEN : KL_CRATE_SECONDARY_COLOR)
    cuboid([width, depth, height], rounding=radius, except=[TOP, BOTTOM]) {

      // chamfering
      tag("remove") color(debug_colors ? HR_BLUE : KL_CRATE_SECONDARY_COLOR) edge_profile(chamfer_edges) mask2d_chamfer(KL_CRATE_RIB_DEPTH);
      // we have to subtract epsilon from the radius, otherwise BambuStudio shows 1 non-manifold edge per mid rib
      tag("remove") color(debug_colors ? HR_GREEN : KL_CRATE_SECONDARY_COLOR) corner_profile(chamfer_edges, r=radius-HR_EPSILON) mask2d_chamfer(KL_CRATE_RIB_DEPTH);

      // cutout inside
      tag("remove") align(CENTER, inside=true)
      color_this(debug_colors ? HR_GREEN : KL_CRATE_SECONDARY_COLOR)
      cuboid([width_inner + HR_EPSILON, depth_inner + HR_EPSILON, height + HR_EPSILON], rounding=KL_CRATE_CORNER_INNER_RADIUS, except=[TOP, BOTTOM]){}

      // cutout stack chamfer if rib_type == TOP
      if (rib_type == KL_CRATE_RIB_TYPE_TOP) {
        // TODO rethink if we should go full RIB_DEPTH (would avoid the need for supports when printing but might spread out the container beneath)
        _stacking_lip_width = KL_CRATE_RIB_DEPTH / 2 - KL_CRATE_GF_TOLERANCE / 2;
        _stacking_lip_radius = radius;
        _stacking_lip_hypothenusis = _stacking_lip_width * sqrt(2);
        tag("remove")
          tag_scope("lip") align(TOP, inside=true, overlap=HR_EPSILON)
          color_this(debug_colors ? HR_RED : KL_CRATE_SECONDARY_COLOR) diff()
          cuboid([width, depth, _stacking_lip_width], rounding=_stacking_lip_radius, except=[TOP, BOTTOM]) {
            tag("remove") color(debug_colors ? HR_GREEN : KL_CRATE_SECONDARY_COLOR) edge_profile(BOTTOM) mask2d_chamfer(_stacking_lip_hypothenusis);
            tag("remove") color(debug_colors ? HR_BLUE : KL_CRATE_SECONDARY_COLOR) corner_profile(BOTTOM, r=_stacking_lip_radius) mask2d_chamfer(_stacking_lip_hypothenusis);
          }
        tag("remove") align(TOP, inside=true)
        color_this(debug_colors ? HR_WHITE : KL_CRATE_SECONDARY_COLOR)
        cuboid([width, depth, PRINTING_LAYER_WIDTH], rounding=_stacking_lip_radius, except=[TOP, BOTTOM]);
      } else if (rib_type == KL_CRATE_RIB_TYPE_BOTTOM) {
        tag("remove") color(debug_colors ? HR_BLUE : KL_CRATE_SECONDARY_COLOR) edge_profile(BOTTOM) mask2d_chamfer(KL_CRATE_RIB_DEPTH / 2  * sqrt(2));
        tag("remove") color(debug_colors ? HR_GREEN : KL_CRATE_SECONDARY_COLOR) corner_profile(BOTTOM, r=radius) mask2d_chamfer(KL_CRATE_RIB_DEPTH / 2  * sqrt(2));
      }
    }
    children();
  }
}

module crate_naked(
  width_inner = GRIDFINITY_BASE_UNIT,
  depth_inner = GRIDFINITY_BASE_UNIT,
  height_inner = GRIDFINITY_BASE_UNIT,
  bottom_strength = KL_CRATE_BOTTOM_STRENGTH_DEFAULT,
  anchor = CENTER,
  spin = 0,
  orient = UP,
  debug_colors = false,
  chamfer_enabled = true
) {

  _outer_width = width_inner + (KL_CRATE_WALL_STRENGTH * 2);
  _outer_depth = depth_inner + (KL_CRATE_WALL_STRENGTH * 2);
  _outer_height = height_inner + bottom_strength;
  _outer_rounding = KL_CRATE_CORNER_INNER_RADIUS + KL_CRATE_WALL_STRENGTH;

  tag_scope("crate_naked")
    attachable(anchor, spin, orient, size=[_outer_width, _outer_depth, _outer_height]) {
      diff()
        cuboid([_outer_width, _outer_depth, _outer_height], rounding=_outer_rounding, except=[TOP, BOTTOM]) {
          align(TOP, inside=true, overlap=HR_EPSILON)
            color_this(debug_colors ? HR_BLUE : KL_CRATE_PRIMARY_COLOR)
              cuboid([width_inner, depth_inner, height_inner], rounding=KL_CRATE_CORNER_INNER_RADIUS, except=[TOP, BOTTOM]);
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
  height * 2 < divider ? 0
  : floor(height / divider) - 1;

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
  height / (count + 1) * (position + 1) + get_horizontal_rib_height(KL_CRATE_RIB_TYPE_MID) / 2;

// Main module for the crate
module crate(
  width_inner = GRIDFINITY_BASE_UNIT,
  depth_inner = GRIDFINITY_BASE_UNIT,
  height_inner = GRIDFINITY_BASE_UNIT,
  bottom_strength = KL_CRATE_BOTTOM_STRENGTH_DEFAULT,
  horizontal_rib_divider = 42,
  debug_colors = false,
  chamfer_enabled = true
) {

  // effective width and depth accounting for tolerance
  _width_effective = width_inner + KL_CRATE_GF_TOLERANCE;
  _depth_effective = depth_inner + KL_CRATE_GF_TOLERANCE;

  // mid rib count
  rib_count = get_rib_mid_count_by_divider(height_inner, horizontal_rib_divider);
  echo("rib_count: ", rib_count);

  color_this(debug_colors ? HR_YELLOW : KL_CRATE_PRIMARY_COLOR)
  diff("crate_naked")
  crate_naked(width_inner=_width_effective, depth_inner=_depth_effective, height_inner=height_inner,
    bottom_strength=bottom_strength, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled) {
    // Bottom rib
    align(BOTTOM, inside=true)
      horizontal_rib_profile(_width_effective, _depth_effective, KL_CRATE_RIB_TYPE_BOTTOM, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);

    // Top rib
    down(KL_CRATE_RIB_DEPTH/2)
    align(TOP, inside=true, overlap=KL_CRATE_RIB_DEPTH)
      horizontal_rib_profile(_width_effective, _depth_effective, KL_CRATE_RIB_TYPE_TOP, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);

    // Mid ribs
    for (i = [0:rib_count - 1]) {
      z = get_rib_mid_z_by_count(height_inner + bottom_strength, rib_count, i);
      align(BOTTOM) {
        up(z) horizontal_rib_profile(_width_effective, _depth_effective, KL_CRATE_RIB_TYPE_MID, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
      }
    }
  }
}
