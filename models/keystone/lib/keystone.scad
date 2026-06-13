// HomeRacker - Keystone
// Copyright (c) 2025 KellerLab (Patrick Pötz)
//
// Licensed under MIT (code) / CC BY-SA 4.0 (models).
// See LICENSE file in the repository root for details.
//
// Parametric keystone jack socket module for HomeRacker panels.
// Provides negative geometry (pocket + socket) that accepts any standard keystone module,
// plus optional snap-fit label plate slots for port identification.
//
// Module hierarchy (outer → inner):
//   keystone_full() → keystone_pocket() → keystone_socket()
//                   → label_recess() → label_hooks()
//
// Usage: call keystone_full() inside a diff("keystone") context on your panel body.
//
// Dimensions based on the Parametric Keystone Connector by Paul Hatcher (CC0):
// https://www.printables.com/model/537480-parametric-keystone-connector

include <BOSL2/std.scad>
include <../../core/lib/constants.scad>

// --- Colors ---

KS_COLOR_PRIMARY = HR_YELLOW;
KS_COLOR_SECONDARY = HR_CHARCOAL;

// --- Keystone Dimensions ---
// All dimensions assume the keystone module is oriented with the clip on top.

KS_WIDTH_INNER = 14.7;       // Inner width of front opening (mm)
KS_BODY_HEIGHT = 22;         // Height of the main keystone body (mm)
_ks_wall_strength = 1.5;     // Wall strength around the keystone (mm)

_ks_front_depth = 1.5;       // Depth of the front plate lip (mm)
_ks_front_chamfer = 1;       // Chamfer on top edge of front opening (mm)
_ks_front_offset_y = 2.85;   // Vertical offset from body bottom to opening bottom (mm)

_ks_body_depth = 6.75;       // Depth of the main body section (mm)
_ks_body_offset_y = 1.350;   // Vertical offset from front to body bottom (mm)

_ks_hook_depth = 1.5;        // Depth of the rear retention hooks (mm)
_ks_hook_height = 19.3;      // Height of the rear hook section (mm)
_ks_hook_chamfer = 1;        // Chamfer on hook edges (mm)

// --- Label Dimensions ---

KS_LABEL_HEIGHT = BASE_UNIT;
KS_LABEL_STRENGTH = BASE_STRENGTH;
KS_LABEL_CHAMFER = TOLERANCE * 4;

// --- Public Dimension Functions ---

/// Returns the outer width of a keystone module including walls and tolerance.
function get_ks_width_outer(additional_tolerance=0.0) =
  KS_WIDTH_INNER + 2 * _ks_wall_strength + additional_tolerance;

/// Returns the outer height of a keystone module including walls and tolerance.
function get_ks_height_outer(additional_tolerance=0.0) =
  KS_BODY_HEIGHT + 2 * _ks_wall_strength + additional_tolerance;

/// Returns the total depth of a keystone module (front lip + body + hooks).
function get_ks_depth_outer() =
  _ks_front_depth + _ks_body_depth + _ks_hook_depth;

/// Returns the inner front opening height with tolerance applied.
function get_ks_height_inner_front(additional_tolerance=0.0) =
  16.4 + additional_tolerance;

/// Returns the effective width accounting for rotation (swaps width/height at 90°/270°).
function get_effective_keystone_width(additional_tolerance=0.0, yrot=0) =
  yrot == 90 || yrot == 270 ? get_ks_height_outer(additional_tolerance) : get_ks_width_outer(additional_tolerance);

/// Returns the effective height accounting for rotation (swaps width/height at 90°/270°).
function get_effective_keystone_height(additional_tolerance=0.0, yrot=0) =
  yrot == 90 || yrot == 270 ? get_ks_width_outer(additional_tolerance) : get_ks_height_outer(additional_tolerance);

/// Returns the vertical offset needed for label slots when keystone is rotated.
function get_label_slot_vertical_offset(yrot=0, additional_tolerance=0.0) =
  yrot == 90 || yrot == 270 ? get_ks_height_outer(additional_tolerance) - get_ks_width_outer(additional_tolerance) : 0;

/// Returns the pocket dimensions [width, depth, height] of a keystone accounting for rotation.
/// Excludes the label recess — use get_label_attachable_height() for label slot height.
function get_keystone_dimensions(yrot=0, additional_tolerance=0.0) = [
  get_effective_keystone_width(additional_tolerance, yrot),
  get_ks_depth_outer(),
  get_effective_keystone_height(additional_tolerance, yrot)
];

/// Returns the total attachable height of the label recess block.
function get_label_attachable_height(yrot=0, additional_tolerance=0.0) =
  KS_LABEL_HEIGHT + TOLERANCE + get_label_slot_vertical_offset(yrot, additional_tolerance) + BASE_STRENGTH;

// --- Debug ---

/// Prints keystone outer dimensions to the console.
module debug_keystone_dimensions(additional_tolerance=0.0) {
  echo("Keystone Module Dimensions:");
  echo("  Width Outer: ", get_ks_width_outer(additional_tolerance), " mm");
  echo("  Height Outer: ", get_ks_height_outer(additional_tolerance), " mm");
  echo("  Depth Outer: ", get_ks_depth_outer(), " mm");
}

// --- Internal Modules ---

/// Creates the inner snap-fit socket geometry that receives a keystone jack.
/// This is the negative shape matching the keystone's 3-section profile
/// (front lip, body, rear hooks with retention chamfers).
/// Must be used within a diff("keystone") context.
module keystone_socket(additional_tolerance=0.0, anchor=CENTER, spin=0, orient=UP, debug_colors=false) {
  _width = KS_WIDTH_INNER + additional_tolerance;
  _depth = _ks_front_depth + _ks_body_depth + _ks_hook_depth;
  _height = KS_BODY_HEIGHT + additional_tolerance;

  attachable(anchor=anchor, spin=spin, orient=orient, size=[_width, _height, _depth]) {
    // Oriented lying on front face — negative chamfers only work on top/bottom faces
    color_this(debug_colors ? HR_YELLOW : KS_COLOR_PRIMARY)
    cuboid([_width, _height, _ks_body_depth]) {
      // Front opening (lip section)
      fwd(_ks_body_offset_y) align(BOTTOM, BACK)
        color(debug_colors ? HR_GREEN : KS_COLOR_PRIMARY)
        cuboid([_width, get_ks_height_inner_front(additional_tolerance), _ks_front_depth],
          chamfer=-_ks_front_chamfer, edges=[TOP+FRONT]);
      // Rear hooks (retention section)
      fwd(_ks_body_offset_y) align(TOP, BACK)
        color(debug_colors ? HR_RED : KS_COLOR_PRIMARY)
        cuboid([_width, _ks_hook_height + additional_tolerance, _ks_hook_depth],
          chamfer=-_ks_hook_chamfer, edges=[TOP+FRONT, TOP+BACK]);
    }
    children();
  }
}

/// Creates a single label hook on the left side. Used in mirrored pairs by label_hooks().
/// When inner=true, produces the mating geometry for the label plate.
/// When inner=false (default), produces the panel-side recess with insertion funnel.
module _label_hook_left(slot_width, slot_depth, slot_height, label_slot_spacing, inner=false,
  anchor=CENTER, spin=0, orient=UP, debug_colors=false) {

  _spacing_sub = inner ? TOLERANCE : 0;
  _color = inner ? KS_COLOR_SECONDARY : KS_COLOR_PRIMARY;
  _hook_width = TOLERANCE;
  _chamfer = inner ? KS_LABEL_CHAMFER : 0;

  attachable(anchor=anchor, spin=spin, orient=orient, size=[slot_width + _hook_width, slot_depth, slot_height]) {
    color_this(debug_colors ? HR_RED : _color)
    left((label_slot_spacing - slot_width - _spacing_sub) / 2)
    cuboid([slot_width, slot_depth, slot_height], chamfer=_chamfer, edges=[BACK, LEFT], except=FRONT) {
      // Hook tab
      _hook_height = inner ? slot_height / 2 : slot_height;
      color_this(debug_colors ? HR_GREEN : _color) fwd(_chamfer)
      align(RIGHT, BACK) cuboid([_hook_width, BASE_STRENGTH - _spacing_sub - _chamfer, _hook_height],
        chamfer=_hook_width, edges=RIGHT);
      // Insertion funnel (panel side only)
      if (!inner) {
        align(FRONT, inside=true)
          color_this(debug_colors ? HR_CHARCOAL : _color)
          cuboid([slot_width + BASE_CHAMFER, BASE_CHAMFER, slot_height + BASE_CHAMFER],
            chamfer=BASE_CHAMFER, edges=BACK);
      }
    }
    children();
  }
}

/// Creates a mirrored pair of label hooks for snap-fit label plate retention.
/// Parameters:
///   yrot   - keystone rotation angle (determines slot spacing)
///   inner  - true for label-plate side geometry, false for panel-side recess
module label_hooks(yrot=0, inner=false, debug_colors=false) {
  _spacing = yrot == 90 || yrot == 270 ? KS_BODY_HEIGHT : KS_WIDTH_INNER;
  _tol_add = inner ? 0 : TOLERANCE;
  _width = KS_LABEL_STRENGTH + _tol_add;
  _height = KS_LABEL_HEIGHT + _tol_add;
  _depth = BASE_STRENGTH * 2;

  _label_hook_left(_width, _depth, _height, label_slot_spacing=_spacing, inner=inner, debug_colors=debug_colors);
  xflip() _label_hook_left(_width, _depth, _height, label_slot_spacing=_spacing, inner=inner, debug_colors=debug_colors);
}

// --- Public Modules ---

/// Generates a standalone label plate that snaps into the label recess.
/// Print this part separately and insert into the panel from the front.
/// Parameters:
///   yrot - keystone rotation angle (determines plate width)
module label_plate(yrot=0, anchor=CENTER, spin=0, orient=UP, debug_colors=false) {
  _spacing = yrot == 90 || yrot == 270 ? KS_BODY_HEIGHT : KS_WIDTH_INNER;
  _width = _spacing - TOLERANCE;
  _depth = BASE_STRENGTH * 3;
  _height = KS_LABEL_HEIGHT;

  attachable(anchor=anchor, spin=spin, orient=orient, size=[_width, _depth, _height]) {
    fwd(BASE_STRENGTH)
    color_this(debug_colors ? HR_YELLOW : KS_COLOR_SECONDARY)
    diff("label_plate_remove")
    cuboid([_width, BASE_STRENGTH, _height], chamfer=KS_LABEL_CHAMFER, except=[BACK, FRONT]) {
      tag("label_plate_remove") edge_mask(BACK, except=[LEFT, RIGHT])
        color_this(debug_colors ? HR_BLUE : KS_COLOR_SECONDARY)
        chamfer_edge_mask(l=_width - BASE_STRENGTH * 2 - TOLERANCE / 2, chamfer=BASE_STRENGTH - PRINTING_LAYER_HEIGHT);
      attach(BACK, FRONT) label_hooks(yrot=yrot, inner=true, debug_colors=debug_colors);
    }
    children();
  }
}

/// Creates the outer pocket carved into a panel body to house a keystone module.
/// Includes the inner socket geometry and extends the pocket to match panel_depth.
/// Must be used within a diff("keystone") context.
/// Parameters:
///   additional_tolerance - extra clearance around the keystone (mm)
///   yrot                 - rotation angle (0, 90, 180, 270)
///   panel_depth          - total depth of the panel being cut into (mm).
///                          When greater than keystone depth, the pocket extends deeper.
module keystone_pocket(additional_tolerance=0.0, yrot=0, panel_depth, debug_colors=false) {
  _panel_depth = is_undef(panel_depth) ? get_ks_depth_outer() : panel_depth;
  assert(_panel_depth >= get_ks_depth_outer(),
    str("panel_depth (", _panel_depth, "mm) must be >= keystone depth (", get_ks_depth_outer(), "mm)"));
  _width_outer = get_ks_width_outer(additional_tolerance);
  _height_outer = get_ks_height_outer(additional_tolerance);
  _depth_outer = get_ks_depth_outer();

  attachable(expose_tags=true, anchor=CENTER, spin=0, axis=UP, orient=UP,
    size=[get_effective_keystone_width(additional_tolerance, yrot), _depth_outer, get_effective_keystone_height(additional_tolerance, yrot)]) {
    yrot(yrot) xrot(270) {
      color_this(debug_colors ? HR_YELLOW : KS_COLOR_PRIMARY)
      cuboid([_width_outer, _height_outer, _depth_outer]) {
        tag("keystone") keystone_socket(additional_tolerance=additional_tolerance, debug_colors=debug_colors)
          // Extend pocket beyond keystone depth if panel is thicker
          align(TOP) color_this(debug_colors ? HR_CHARCOAL : KS_COLOR_PRIMARY)
            cuboid([_width_outer, _height_outer + EPSILON, _panel_depth - _depth_outer]);
      }
    }
    children();
  }
}

/// Creates the recess for snap-fit label hooks on the panel front face.
/// Must be used within a diff("keystone") context.
/// Parameters:
///   label_position - "above" (default) or "below": which side of the jack the recess sits on
module label_recess(additional_tolerance=0.0, yrot=0,
  anchor=CENTER, spin=0, orient=UP, debug_colors=false, label_position="above") {

  assert(label_position == "above" || label_position == "below",
    str("label_position must be 'above' or 'below', got: '", label_position, "'"));
  _width = get_effective_keystone_width(additional_tolerance, yrot);
  _depth = BASE_STRENGTH * 3;
  _height = get_label_attachable_height(yrot, additional_tolerance);
  _below = label_position == "below";

  attachable(expose_tags=true, anchor=anchor, spin=spin, orient=orient, size=[_width, _depth, _height]) {
    color_this(debug_colors ? HR_BLUE : KS_COLOR_PRIMARY)
    cuboid([_width, _depth, _height]) {
      tag("keystone") align(FRONT, _below ? TOP : BOTTOM, inside=true)
        up((_below ? -1 : 1) * get_label_slot_vertical_offset(yrot, additional_tolerance))
        label_hooks(yrot=yrot, debug_colors=debug_colors);
    }
    children();
  }
}

/// Primary entry point — generates a complete keystone module with pocket, socket,
/// and optional label plate slots. Designed to be used within a diff("keystone") context.
/// Parameters:
///   add_label_slots      - include snap-fit label plate recesses (default: true)
///   show_label           - render a label plate in place for preview (default: false)
///   label_plate_mode     - "assembly": label in front (default); "plate": label above on same plane
///   label_plate_gap      - extra upward offset for plate mode (mm, default: 0)
///   additional_tolerance - extra clearance around the keystone (mm)
///   yrot                 - rotation angle: 0, 90, 180, 270 (degrees)
///   panel_depth          - depth of the panel being cut into (mm, default: keystone depth)
///   label_position       - "above" (default) or "below": which side of the jack the label sits on
module keystone_full(add_label_slots=true, show_label=false, label_plate_mode="assembly",
  label_plate_gap=0, additional_tolerance=0.0, yrot=0,
  panel_depth, anchor=CENTER, spin=0, orient=UP, debug_colors=false, label_position="above") {

  assert(label_plate_mode == "assembly" || label_plate_mode == "plate",
    str("label_plate_mode must be 'assembly' or 'plate', got: '", label_plate_mode, "'"));
  assert(label_position == "above" || label_position == "below",
    str("label_position must be 'above' or 'below', got: '", label_position, "'"));
  assert(!show_label || add_label_slots,
    "show_label requires add_label_slots=true");

  _panel_depth = is_undef(panel_depth) ? get_ks_depth_outer() : panel_depth;
  assert(_panel_depth >= get_ks_depth_outer(),
    str("panel_depth (", _panel_depth, "mm) must be >= keystone depth (", get_ks_depth_outer(), "mm)"));
  _below = label_position == "below";
  _label_anchor = _below ? BOTTOM : TOP;
  _label_height = add_label_slots ? get_label_attachable_height(yrot, additional_tolerance) : 0;
  _width = get_effective_keystone_width(additional_tolerance=additional_tolerance, yrot=yrot);
  _depth = get_ks_depth_outer();
  _height = get_effective_keystone_height(additional_tolerance=additional_tolerance, yrot=yrot) + _label_height;

  attachable(expose_tags=true, anchor=anchor, spin=spin, orient=orient, size=[_width, _depth, _height]) {
    up((_below ? 1 : -1) * _label_height / 2)
    keystone_pocket(additional_tolerance=additional_tolerance, yrot=yrot, panel_depth=_panel_depth, debug_colors=debug_colors) {
      if (add_label_slots) {
        align(_label_anchor, FRONT) label_recess(additional_tolerance=additional_tolerance, yrot=yrot, label_position=label_position, debug_colors=debug_colors) {
          if (show_label && label_plate_mode == "assembly") {
            fwd(BASE_STRENGTH) up((_below ? 1 : -1) * BASE_STRENGTH)
              align(FRONT, _label_anchor) label_plate(yrot=yrot, debug_colors=debug_colors);
          }
          if (show_label && label_plate_mode == "plate") {
            up((_below ? -1 : 1) * (KS_LABEL_HEIGHT/2 + TOLERANCE + label_plate_gap))
              align(_label_anchor) label_plate(yrot=yrot, orient=UP, debug_colors=debug_colors);
          }
        }
      }
    }
    children();
  }
}

/// Demo panel showing a single keystone mounted in a 1U-height panel strip.
/// Useful for visualization and testing. Used by the parts/keystone_sample.scad file.
module keystone_demo_panel(additional_tolerance=0.0, yrot=0, panel_depth, add_label=true,
  label_plate_mode="assembly", label_plate_gap=0, debug_colors=false, label_position="above") {
  assert(label_plate_mode == "assembly" || label_plate_mode == "plate",
    str("label_plate_mode must be 'assembly' or 'plate', got: '", label_plate_mode, "'"));
  _panel_depth = is_undef(panel_depth) ? get_ks_depth_outer() : panel_depth;
  _ks_depth = get_ks_depth_outer();
  _width = get_effective_keystone_width(additional_tolerance=additional_tolerance, yrot=yrot);
  _height = STD_UNIT_HEIGHT;
  _orient = label_plate_mode == "plate" ? FRONT : UP;

  attachable(expose_tags=true, anchor=CENTER, spin=0, axis=UP, orient=_orient, size=[_width, _ks_depth, _height]) {
    fwd(_ks_depth / 2 - BASE_STRENGTH / 2)
    diff("keystone")
    color_this(debug_colors ? HR_WHITE : KS_COLOR_PRIMARY)
    cuboid([_width, BASE_STRENGTH, STD_UNIT_HEIGHT]) {
      align(FRONT, BOTTOM, inside=true) {
        keystone_full(add_label_slots=add_label, show_label=add_label,
          label_plate_mode=label_plate_mode, label_plate_gap=label_plate_gap,
          label_position=label_position,
          additional_tolerance=additional_tolerance, yrot=yrot,
          panel_depth=_panel_depth, debug_colors=debug_colors);
      }
    }
    children();
  }
}
