// HomeRacker - Bracket
//
// This file is part of HomeRacker implementation by KellerLab.
// It contains the bracket module — a clamp that wraps a device from above and
// hangs it in a HomeRacker frame via lock pins.
//
// The part has two halves: a shell that grips the device (top plate with a window,
// plus side walls reaching down as far as you want) and a pair of mount wings on
// the left and right that cap the vertical supports. The wings widen by whatever
// the device width misses on the 15mm grid, so the lock pin holes always land on
// a support no matter how odd the device measures.
//
// Use cases: hanging network gear, mini PCs, power bricks or any box-shaped device
//            in a rack, and as the device-holding half of larger mounts.
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
include <../../core/lib/lockpin.scad>

// Hidden constants for the bracket library (no Customizer section marker)
HR_BRACKET_PRIMARY_COLOR = HR_YELLOW;

// Front-to-back footprint of a mount wing: one support unit plus its enclosing walls.
BRACKET_MOUNT_DEPTH = BASE_UNIT + BASE_STRENGTH*2 + TOLERANCE;

// Default overlap of shell material on the device, in mm.
BRACKET_DEFAULT_STRENGTH = 7.5;

// Shallowest device that still leaves room for one column of mount wings.
BRACKET_MIN_DEVICE_DEPTH = BASE_UNIT;

// Lowest device the bridge can span: its skeleton cutout is rounded by half a unit,
// and the rounding has to fit between the bridge floor and its chamfered top.
BRACKET_MIN_DEVICE_HEIGHT = BASE_UNIT/2 + BASE_CHAMFER*2 - TOLERANCE/2;

/** Bracket shell module
  * The clamp that sits on the device: a top plate with a window cut out of it and
  * side walls running down the device flanks.
  * @param device_width Device width in mm, tolerance already applied.
  * @param device_depth Device depth in mm, tolerance already applied.
  * @param device_height Device height in mm.
  * @param strength_top How far the top plate reaches inward over the device.
  * @param strength_sides How far the side walls reach down the device.
  * @param outer_depth Outer depth of the shell in mm.
  */
module bracket_shell(device_width, device_depth, device_height,
  strength_top, strength_sides, outer_depth,
  color=HR_BRACKET_PRIMARY_COLOR, debug_colors=false, disable_chamfer=false) {

  _chamfer = disable_chamfer ? 0 : BASE_CHAMFER;
  _strength_sides = min(strength_sides, device_height - BASE_STRENGTH);
  // The top plate can reach inward at most to the middle of the device.
  _strength_top_limit = min(device_depth, device_width)/2;
  _strength_top = min(strength_top, _strength_top_limit);

  _width = device_width + BASE_STRENGTH*2;
  _height = _strength_sides + BASE_STRENGTH;
  _z = device_height/2 - _height/2 + BASE_STRENGTH;

  // A window that reaches the limit leaves no top plate at all, so a chamfer there
  // would bite into the side walls instead of breaking a real edge.
  _window_chamfer = _strength_top == _strength_top_limit ? 0 : -_chamfer;

  tag_scope("bracket_shell")
  diff()
  color_this(debug_colors ? HR_GREEN : color)
  up(_z)
  cuboid([_width, outer_depth, _height], chamfer=_chamfer) {
    // Device volume
    tag("remove") down(_z) cuboid([device_width, device_depth, device_height]);
    // Window in the top plate
    tag("remove") cuboid([device_width - _strength_top*2, device_depth - _strength_top*2, _height],
      chamfer=_window_chamfer);
  }
}

/** Bracket mount module
  * A single mount wing on the left of the device: a skeletonised bridge out to the
  * support, then a U-shaped cap around it with a lock pin hole through both sides.
  * The wing is placed relative to the device, because its width is what aligns the
  * lock pin hole to the 15mm grid.
  * @param device_width Device width in mm, tolerance already applied.
  * @param device_height Device height in mm.
  */
module bracket_mount(device_width, device_height,
  color=HR_BRACKET_PRIMARY_COLOR, debug_colors=false, disable_chamfer=false) {

  _chamfer = disable_chamfer ? 0 : BASE_CHAMFER;

  // Round the clear span between the supports up to the grid, then split what the
  // device misses across the two wings. A width already on the grid needs no widening.
  _support_span = ceil((device_width - HR_EPSILON) / BASE_UNIT) * BASE_UNIT;
  _grid_offset = max(0, (_support_span - device_width)/2);
  _width = BASE_UNIT + _grid_offset;

  _height = device_height + BASE_STRENGTH + TOLERANCE/2 - BASE_CHAMFER;
  _z = (BASE_STRENGTH - TOLERANCE/2 - BASE_CHAMFER)/2;

  _bridge_width = _width - BASE_STRENGTH;
  _bridge_height = _height - BASE_CHAMFER;
  _cap_height = BASE_UNIT;
  _cap = [_width, BASE_STRENGTH, _cap_height];

  left(device_width/2 + _width/2)
  up(_z)
  union() {
    // Bridge from shell to mount, hollowed out from below to save material
    difference() {
      color_this(debug_colors ? HR_RED : color)
      up(BASE_STRENGTH - BASE_CHAMFER/2)
      cuboid([_bridge_width + BASE_STRENGTH, BRACKET_MOUNT_DEPTH, _bridge_height],
        chamfer=_chamfer, except=BOTTOM);

      left(BASE_STRENGTH/2)
      up(BASE_CHAMFER/2)
      cuboid([_bridge_width, BASE_UNIT, _bridge_height - BASE_STRENGTH],
        chamfer=BASE_UNIT/2, edges=[FRONT+BOTTOM, BACK+BOTTOM]);
    }

    // U-shaped cap around the support, secured by a lock pin
    tag_scope("bracket_mount")
    diff() {
      color_this(debug_colors ? HR_BLUE : color)
      back(BRACKET_MOUNT_DEPTH/2 - BASE_STRENGTH/2)
      down(_height/2 + _cap_height/2)
      cuboid(_cap, chamfer=_chamfer, edges=BACK, except=TOP);

      color_this(debug_colors ? HR_BLUE : color)
      fwd(BRACKET_MOUNT_DEPTH/2 - BASE_STRENGTH/2)
      down(_height/2 + _cap_height/2)
      cuboid(_cap, chamfer=_chamfer, edges=FRONT, except=TOP);

      color_this(debug_colors ? HR_BLUE : color)
      down(_height/2 - BASE_STRENGTH/2)
      cuboid([_width, BRACKET_MOUNT_DEPTH, BASE_STRENGTH],
        chamfer=_chamfer, edges=[FRONT, BACK], except=[TOP, BOTTOM]);

      // Lock pin hole, centred on the support the wing caps
      tag("remove")
      left(_width/2 - BASE_UNIT/2)
      down(_height/2 + _cap_height/2)
      lockpin_hole(depth=BRACKET_MOUNT_DEPTH + HR_EPSILON, orient=BACK,
        chamfer_top=!disable_chamfer, chamfer_bottom=!disable_chamfer);
    }
  }
}

/** Bracket mount pair module
  * Mirrored mount wings on both flanks of the device.
  * @param device_width Device width in mm, tolerance already applied.
  * @param device_height Device height in mm.
  */
module bracket_mount_pair(device_width, device_height,
  color=HR_BRACKET_PRIMARY_COLOR, debug_colors=false, disable_chamfer=false) {
  xflip_copy()
  bracket_mount(device_width, device_height,
    color=color, debug_colors=debug_colors, disable_chamfer=disable_chamfer);
}

/** Bracket module
  * The full printable part: shell plus one or two columns of mount wings.
  * Device dimensions are nominal, the standard TOLERANCE is added internally.
  * The attachable bounding box covers the shell only, the wings reach beyond it.
  * @param device_width Device width in mm.
  * @param device_depth Device depth in mm.
  * @param device_height Device height in mm.
  * @param strength_top How far the top plate reaches inward over the device.
  * @param strength_sides How far the side walls reach down the device.
  * @param mount_offset_y Pushes the wings back from the front edge, for mounts that
  *                       need to sit flush behind something such as a front panel.
  * @param mount_columns Wing columns, 1 or 2. Left undefined, it picks 2 whenever
  *                      the device is deep enough for them to clear each other.
  */
module bracket(device_width, device_depth, device_height,
  strength_top=BRACKET_DEFAULT_STRENGTH, strength_sides=BRACKET_DEFAULT_STRENGTH,
  mount_offset_y=0, mount_columns=undef,
  color=HR_BRACKET_PRIMARY_COLOR, debug_colors=false, disable_chamfer=false,
  anchor=CENTER, spin=0, orient=UP) {

  assert(device_width > 0, "Device width must be positive");
  assert(device_depth >= BRACKET_MIN_DEVICE_DEPTH,
    str("Device depth must be at least ", BRACKET_MIN_DEVICE_DEPTH, "mm to fit a mount wing"));
  assert(device_height >= BRACKET_MIN_DEVICE_HEIGHT,
    str("Device height must be at least ", BRACKET_MIN_DEVICE_HEIGHT, "mm"));
  assert(strength_top >= BASE_STRENGTH && strength_sides >= BASE_STRENGTH,
    str("Shell strengths must be at least ", BASE_STRENGTH, "mm, thinner walls would not hold the device"));
  assert(mount_offset_y >= 0 && mount_offset_y <= device_depth - BRACKET_MIN_DEVICE_DEPTH,
    str("Mount offset must be between 0 and ", device_depth - BRACKET_MIN_DEVICE_DEPTH,
        "mm at this device depth, beyond that the wings hang off the back of the shell"));
  assert(is_undef(mount_columns) || mount_columns == 1 || mount_columns == 2,
    "Mount columns must be 1 or 2");

  _width = device_width + TOLERANCE;
  _depth = device_depth + TOLERANCE;
  _outer_depth = _depth + BASE_STRENGTH*2;
  _strength_sides = min(strength_sides, device_height - BASE_STRENGTH);

  // Wings sit on the 15mm grid, so the usable spacing rounds down to a multiple of it.
  _max_spacing = floor((_outer_depth - mount_offset_y - BRACKET_MOUNT_DEPTH) / BASE_UNIT) * BASE_UNIT;
  _columns = is_undef(mount_columns) ? (_max_spacing >= BRACKET_MOUNT_DEPTH ? 2 : 1) : mount_columns;
  _spacing = _columns > 1 ? _max_spacing : 0;
  // Without an offset the wings stay centred, otherwise they line up behind it.
  _shift_y = mount_offset_y > 0 ? (-_outer_depth + _spacing + BRACKET_MOUNT_DEPTH)/2 + mount_offset_y : 0;

  assert(_columns < 2 || _max_spacing >= BRACKET_MOUNT_DEPTH,
    str("Two mount columns need a device depth of at least ",
        BASE_UNIT*3 + mount_offset_y, "mm at this mount offset, otherwise they overlap"));

  attachable(anchor=anchor, spin=spin, orient=orient,
    size=[_width + BASE_STRENGTH*2, _outer_depth, _strength_sides + BASE_STRENGTH]) {
    down((device_height + BASE_STRENGTH - _strength_sides)/2)
    union() {
      bracket_shell(_width, _depth, device_height, strength_top, _strength_sides, _outer_depth,
        color=color, debug_colors=debug_colors, disable_chamfer=disable_chamfer);

      back(_shift_y)
      ycopies(spacing=_spacing, n=_columns)
      bracket_mount_pair(_width, device_height,
        color=color, debug_colors=debug_colors, disable_chamfer=disable_chamfer);
    }
    children();
  }
}
