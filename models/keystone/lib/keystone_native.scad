// HomeRacker - Keystone (native geometry)
// Copyright (c) 2025 KellerLab (Patrick Pötz)
//
// Licensed under MIT (code) / CC BY-SA 4.0 (models).
//
// BOSL2-FREE native geometry for the keystone cutter. Kept in a separate file with
// NO `include <BOSL2/std.scad>` so its primitives (polygon, linear_extrude, cube)
// resolve to the OpenSCAD built-ins. Pulled into keystone.scad via `use <>`.
//
// DISCLAIMER: this native geometry was fully AI-transpiled from the original BOSL2 code in
// keystone.scad. It was print-tested with no noticeable difference from the BOSL2 version,
// but the BOSL2 path remains the authored source of truth — prefer it if in doubt.
//
// Why: `include <BOSL2/std.scad>` overrides the built-in primitives with attachable
// wrappers, which gives every instance a unique node signature and defeats OpenSCAD's
// automatic identical-subtree geometry caching. A dense panel re-evaluates each jack's
// chamfer geometry from scratch. Building the cutter from genuine native primitives here
// lets OpenSCAD compute one jack's mesh once and re-stamp it for every identical jack.
//
// The socket is a prism: a fixed (Z,Y) side-profile extruded along X (width). The two
// negative chamfers are outward 45° flares at the front-opening lead-in and the rear-hook
// edges, reproduced here as explicit profile vertices.

/// Native keystone socket cutter, centered at origin, prism axis along X.
/// All dimensions are passed in from keystone.scad so this file stays BOSL2-free and
/// has no dependency on the constants module.
module ks_socket_native(width, height, body_depth, front_depth, front_height,
  front_chamfer, body_offset_y, hook_depth, hook_height, hook_chamfer) {

  _h2 = height / 2;
  _bd2 = body_depth / 2;
  _f_ymax = _h2 - body_offset_y;
  _f_ymin = _h2 - front_height - body_offset_y;
  _h_ymax = _h2 - body_offset_y;
  _h_ymin = _h2 - hook_height - body_offset_y;

  // Profile points are [Z, Y]; rotate([0,-90,0]) maps the extrude so [Z,Y]->(Y_final,Z_final)
  // and the extrude axis becomes X with length = width.
  rotate([0, -90, 0])
    linear_extrude(height = width, center = true)
      union() {
        // Main body
        polygon([
          [-_bd2, -_h2], [-_bd2, _h2], [_bd2, _h2], [_bd2, -_h2],
        ]);
        // Front opening (negative chamfer flares the top-front lead-in edge)
        polygon([
          [-_bd2, _f_ymax],
          [-_bd2 - front_depth, _f_ymax],
          [-_bd2 - front_depth, _f_ymin],
          [-_bd2 - front_chamfer, _f_ymin],
          [-_bd2, _f_ymin - front_chamfer],
        ]);
        // Rear hooks (negative chamfers flare both outer edges)
        polygon([
          [_bd2, _h_ymin],
          [_bd2, _h_ymax],
          [_bd2 + hook_depth - hook_chamfer, _h_ymax],
          [_bd2 + hook_depth, _h_ymax + hook_chamfer],
          [_bd2 + hook_depth, _h_ymin - hook_chamfer],
          [_bd2 + hook_depth - hook_chamfer, _h_ymin],
        ]);
      }
}

/// Native panel-side label-hooks cutter (the `inner=false` recess geometry), centered at
/// origin. Reproduces the BOSL2 `label_hooks(inner=false)` shape from three native pieces so
/// identical jacks share one cached mesh: a plain slot box, a chamfered hook tab (hull of the
/// full base rectangle to the inset outer face), and an insertion funnel (hull of the full
/// front rectangle to the inset back face). Built as a mirrored pair about X.
/// All dimensions are passed in from keystone.scad so this file stays BOSL2-free.
module ks_label_hooks_native(slot_width, slot_depth, slot_height, label_slot_spacing,
  hook_width, base_chamfer, strength) {

  _ks_label_hook_single(slot_width, slot_depth, slot_height, label_slot_spacing,
    hook_width, base_chamfer, strength);
  mirror([1, 0, 0])
    _ks_label_hook_single(slot_width, slot_depth, slot_height, label_slot_spacing,
      hook_width, base_chamfer, strength);
}

/// Single left-side label hook (slot + tab + funnel). Mirrored by ks_label_hooks_native().
module _ks_label_hook_single(slot_width, slot_depth, slot_height, label_slot_spacing,
  hook_width, base_chamfer, strength) {

  _eps = 0.001;
  _left = (label_slot_spacing - slot_width) / 2;  // slot center sits at X = -_left
  _sw2 = slot_width / 2;
  _sd2 = slot_depth / 2;
  _right = -_left + _sw2;  // slot right (+X) face

  union() {
    // Main slot — plain box (panel-side chamfer is 0).
    translate([-_left, 0, 0])
      cube([slot_width, slot_depth, slot_height], center = true);

    // Hook tab — frustum from the full base rectangle at the slot right face to the
    // outer face inset by hook_width on all four sides (the BOSL2 chamfer=hook_width).
    hull() {
      translate([_right, strength / 2, 0])
        cube([_eps, strength, slot_height], center = true);
      translate([_right + hook_width, strength / 2, 0])
        cube([_eps, strength - 2 * hook_width, slot_height - 2 * hook_width], center = true);
    }

    // Insertion funnel — frustum flaring the slot front opening: full rectangle flush with
    // the slot front face (Y = -_sd2) to the back rectangle inset by base_chamfer, flush at
    // Y = -_sd2 + base_chamfer (the BOSL2 chamfer=BACK 45° flare). Slabs sit flush against
    // their planes so the 45° slope spans exactly base_chamfer in Y (no _eps overhang).
    hull() {
      translate([-_left, -_sd2 + _eps / 2, 0])
        cube([slot_width + base_chamfer, _eps, slot_height + base_chamfer], center = true);
      translate([-_left, -_sd2 + base_chamfer - _eps / 2, 0])
        cube([slot_width - base_chamfer, _eps, slot_height - base_chamfer], center = true);
    }
  }
}

/// 45° chamfer wedge running along the X axis (cross-section in the Y/Z plane), centered.
/// Removes a `c`×`c` right-triangle notch from the edge it is centered on. Length `len`.
module _ks_wedge_x(len, c) {
  rotate([45, 0, 0]) cube([len, c * sqrt(2), c * sqrt(2)], center = true);
}

/// 45° chamfer wedge running along the Z axis (cross-section in the X/Y plane), centered.
module _ks_wedge_z(len, c) {
  rotate([0, 0, 45]) cube([c * sqrt(2), c * sqrt(2), len], center = true);
}

/// Native panel-side label PLATE — the printed snap-fit part (the BOSL2 `label_plate()`
/// body+grip+inner-hooks). Built BOSL2-free from native primitives so identical plates share
/// one cached mesh across a populated panel (BOSL2 attachable defeats that cache). Constructed
/// in the same final frame as `label_plate()` (envelope depth = body_depth + hook_depth,
/// centered; body at the front, inner hooks extending back). Mirror-symmetric about X.
module ks_label_plate_native(plate_width, body_depth, plate_height, body_chamfer,
  grip_len, grip_chamfer, hook_spacing, hook_slot_width, hook_depth, hook_chamfer,
  spacing_sub, tab_width, tab_depth) {

  _hw = plate_width / 2;
  _hh = plate_height / 2;
  _env_half = (body_depth + hook_depth) / 2;       // envelope half-depth in Y
  _body_cy = -_env_half + body_depth / 2;           // body centre Y (front block)
  _body_back = _body_cy + body_depth / 2;           // body back face (= hook front)
  _slot_cx = (hook_spacing - hook_slot_width - spacing_sub) / 2;  // |X| of slot centre
  _slot_hw = hook_slot_width / 2;
  _slot_cy = _body_back + hook_depth / 2;           // slot centre Y
  _slot_back = _slot_cy + hook_depth / 2;           // slot back face (+Y)

  difference() {
    union() {
      // --- Plate body: prism along Y with the 4 Y-parallel corner edges chamfered. ---
      translate([0, _body_cy, 0])
        rotate([90, 0, 0])
          linear_extrude(height = body_depth, center = true)
            polygon([
              [_hw, _hh - body_chamfer], [_hw - body_chamfer, _hh],
              [-(_hw - body_chamfer), _hh], [-_hw, _hh - body_chamfer],
              [-_hw, -(_hh - body_chamfer)], [-(_hw - body_chamfer), -_hh],
              [_hw - body_chamfer, -_hh], [_hw, -(_hh - body_chamfer)],
            ]);

      // --- Inner hooks (mirrored pair): chamfered slot + retention tab. ---
      _ks_label_plate_hook(_slot_cx, _slot_hw, _hh, _slot_cy, hook_depth, _slot_back,
        hook_chamfer, tab_width, tab_depth, plate_height);
      mirror([1, 0, 0])
        _ks_label_plate_hook(_slot_cx, _slot_hw, _hh, _slot_cy, hook_depth, _slot_back,
          hook_chamfer, tab_width, tab_depth, plate_height);
    }

    // --- Finger grip: 45° chamfers on the body back top & bottom edges, central length. ---
    // grip_len + 0.1 bleeds the wedge past each end, matching BOSL2 chamfer_edge_mask's `excess`.
    for (z = [1, -1])
      translate([0, _body_back, z * _hh])
        _ks_wedge_x(grip_len + 0.1, grip_chamfer);
  }
}

/// One left-side inner hook of the label plate (chamfered slot + retention tab). The slot
/// sits at X = -slot_cx with its LEFT (outer −X) and BACK (+Y) edges chamfered; the tab is a
/// small nub on the slot's inner (+X) face near the back. Mirrored by ks_label_plate_native().
module _ks_label_plate_hook(slot_cx, slot_hw, half_h, slot_cy, slot_depth, slot_back,
  chamfer, tab_width, tab_depth, plate_height) {

  _eps = 0.01;
  _slot_in = -slot_cx + slot_hw;   // slot inner (+X) face
  _tab_back = slot_back - chamfer; // tab back face (fwd by chamfer from slot back)
  _tab_cy = _tab_back - tab_depth / 2;
  _tab_h = plate_height / 2;

  difference() {
    union() {
      // Slot: prism along Y with the two LEFT (−X) corner edges chamfered over full depth.
      translate([-slot_cx, slot_cy, 0])
        rotate([90, 0, 0])
          linear_extrude(height = slot_depth, center = true)
            polygon([
              [slot_hw, half_h], [-slot_hw + chamfer, half_h], [-slot_hw, half_h - chamfer],
              [-slot_hw, -(half_h - chamfer)], [-slot_hw + chamfer, -half_h], [slot_hw, -half_h],
            ]);

      // Retention tab: a nub on the slot inner (+X) face, its outer (+X) face edges chamfered
      // via a front-to-tip frustum (full base at the slot face, inset tip by tab_width).
      hull() {
        translate([_slot_in + _eps / 2, _tab_cy, 0])
          cube([_eps, tab_depth, _tab_h], center = true);
        translate([_slot_in + tab_width - _eps / 2, _tab_cy, 0])
          cube([_eps, tab_depth - 2 * tab_width, _tab_h - 2 * tab_width], center = true);
      }
    }

    // Back-cap chamfers: bevel the 4 edges of the slot back (+Y) face.
    translate([-slot_cx, slot_back, half_h]) _ks_wedge_x(2 * slot_hw + 2 * chamfer, chamfer);
    translate([-slot_cx, slot_back, -half_h]) _ks_wedge_x(2 * slot_hw + 2 * chamfer, chamfer);
    translate([-slot_cx + slot_hw, slot_back, 0]) _ks_wedge_z(2 * half_h + 2 * chamfer, chamfer);
    translate([-slot_cx - slot_hw, slot_back, 0]) _ks_wedge_z(2 * half_h + 2 * chamfer, chamfer);
  }
}
