// HomeRacker - Panel Split Library
//
// This library contains the split module used to create a vertical split in panels,
// allowing for printing in multiple parts (e.g. 19" rack panels).
// The split module creates a vertical cut on the body it's attached to
// and adds connecting features (basically a vertical support + sleeve)

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



// the split connectors are meant to connect standard rackpanels together (e.g. 19" rack panels)
// so one can print the panels in multiple parts and connect them with the split connectors.
// A split connector is BOSL2-attachable and can be placed on the panel body (similar to the keystone module)
// it will create a hinge-like connection between the two halves of the panel,
// that will be locked in place via a single lock pin
// (like the rod of a hinge, but with the lock pin tension mechanism in the center).
// The center part is always a full BASE_UNIT and the counter knuckles are the rest that remains from a standard height unit (44.45mm).
// When a panel is >1HU, this pattern can be repeated (mirrored per unit) to create an alternating pattern of knuckles,
// where every height unit has a center lock knuckle.
// note: this has to be properly rephrased by AI in the end!
// this thing is currently only designed for standard rack panels height-wise. if we want to split arbitrary panels in the future,
// we would need to make the knuckle heights more flexible and not based on the standard unit height.

include <BOSL2/std.scad>
include <../../core/lib/support.scad>
include <../../core/lib/lockpin.scad>

//tmp
include <../../panel/lib/rackpanel.scad>

knuckle_side = "all"; // [all:Complete, left:left, right:right]
units = 2; // [1:1:8]
debug_colors = true; // [false,true]
enable_chamfer = true; // [false,true]

_LOCKPIN_HOLE_CENTER_SIDE = LOCKPIN_HOLE_SIDE_LENGTH + PRINTING_LAYER_WIDTH*2;
HR_SPLIT_KNUCKLE_STRENGTH_SLIM = _LOCKPIN_HOLE_CENTER_SIDE + BASE_STRENGTH*2;
HR_SPLIT_KNUCKLE_STRENGTH_BASE = BASE_UNIT;

HR_SPLIT_KNUCKLE_TYPE_LOCK = 0;
HR_SPLIT_KNUCKLE_TYPE_REGULAR = 1;


function get_knuckle_height(knuckle_type) =
  knuckle_type == HR_SPLIT_KNUCKLE_TYPE_LOCK ? BASE_UNIT :
  knuckle_type == HR_SPLIT_KNUCKLE_TYPE_REGULAR ? (STD_UNIT_HEIGHT - BASE_UNIT) / 2 - TOLERANCE/2 - TOLERANCE/4 :
  die(str("Invalid knuckle type: ", knuckle_type));


function get_split_connector_width(knuckle_strength) =
  knuckle_strength + TOLERANCE; // adds tolerance/2 for the bridge on each side

// the x-axis anchors (left/right) are intentionally chosen too big, as they only make sense in a combination of 3 knuckles,
// with 2 regular ones on the outside and one lock on the inside. It's meant so the bridges are aligned as intended
module knuckle(knuckle_type, knuckle_strength=HR_SPLIT_KNUCKLE_STRENGTH_SLIM,
  panel_depth=BASE_STRENGTH,
  anchor=CENTER, spin=0, orient=UP,
  debug_colors=false, chamfer_enabled=true) {

  assert(knuckle_type == HR_SPLIT_KNUCKLE_TYPE_LOCK || knuckle_type == HR_SPLIT_KNUCKLE_TYPE_REGULAR,
    "Invalid knuckle type");

  attachable_width = get_split_connector_width(knuckle_strength);
  attachable_depth = HR_SPLIT_KNUCKLE_STRENGTH_SLIM;
  attachable_height = get_knuckle_height(knuckle_type);

  attachable(anchor=anchor, spin=spin, orient=orient, size=[attachable_width, attachable_depth, attachable_height]) {

    color_this(debug_colors ? HR_BLUE : HR_CORE_SUPPORT_SECONDARY_COLOR)
    // main knuckle body
    diff()
    cuboid([knuckle_strength, HR_SPLIT_KNUCKLE_STRENGTH_SLIM, attachable_height], chamfer=chamfer_enabled ? BASE_CHAMFER : 0, except=FRONT){
      // minimal bridge to connect knuckle to the leaves
      _bridge_width = TOLERANCE/2 + BASE_CHAMFER;
      color_this(debug_colors ? HR_GREEN : HR_CORE_SUPPORT_SECONDARY_COLOR)
      if (knuckle_type == HR_SPLIT_KNUCKLE_TYPE_LOCK) {
        align(LEFT,FRONT,overlap=BASE_CHAMFER) cuboid([_bridge_width, panel_depth, attachable_height]);
      } else {
        align(RIGHT,FRONT,overlap=BASE_CHAMFER) cuboid([_bridge_width, panel_depth, attachable_height]);
      }

      // lock pin hole for the knuckle (lock knuckle needs a lock pin hole from the support module, others just a 4x4mm hole)
      color_this(debug_colors ? HR_YELLOW : HR_CORE_SUPPORT_SECONDARY_COLOR)
      align(CENTER) tag("remove")
      if (knuckle_type == HR_SPLIT_KNUCKLE_TYPE_LOCK) {
        lockpin_hole_support();
      } else {
        cuboid([LOCKPIN_HOLE_SIDE_LENGTH,LOCKPIN_HOLE_SIDE_LENGTH,attachable_height+HR_EPSILON], chamfer=chamfer_enabled ? -LOCKPIN_HOLE_CHAMFER : 0, edges=[TOP,BOTTOM]);
      }
    }

    children();
  }
}

// units as in Rack Units (1U = 1.75 inches = 44.45mm),
// so units=2 means a 2U split (88.9mm)

HR_SPLIT_KNUCKLE_SIDE_ALL = "all";
HR_SPLIT_KNUCKLE_SIDE_LEFT = "left";
HR_SPLIT_KNUCKLE_SIDE_RIGHT = "right";

function invert_knuckle_side(side) =
  side == HR_SPLIT_KNUCKLE_SIDE_LEFT ? HR_SPLIT_KNUCKLE_SIDE_RIGHT :
  side == HR_SPLIT_KNUCKLE_SIDE_RIGHT ? HR_SPLIT_KNUCKLE_SIDE_LEFT :
  side; // if it's "all" or any other value, return it unchanged


module split_connector(
  units=1, panel_depth=BASE_STRENGTH,
  knuckle_strength=HR_SPLIT_KNUCKLE_STRENGTH_SLIM, knuckle_side=HR_SPLIT_KNUCKLE_SIDE_ALL,
  anchor=CENTER, spin=0, orient=UP,
  debug_colors=false, chamfer_enabled=true) {


  module split_connector_1HU(invert=false) {

    _effective_knuckle_side = invert ? invert_knuckle_side(knuckle_side) : knuckle_side;

    _tag_left = (_effective_knuckle_side == HR_SPLIT_KNUCKLE_SIDE_RIGHT) ? "remove" : "show";
    _tag_right = (_effective_knuckle_side == HR_SPLIT_KNUCKLE_SIDE_LEFT) ? "remove" : "show";

    diff()
    mirror([invert ? 1 : 0,0,0])
    tag_scope("split_connector")
    tag(_tag_right)
    knuckle(HR_SPLIT_KNUCKLE_TYPE_REGULAR, knuckle_strength=knuckle_strength, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled){
      attach(TOP,BOTTOM,overlap=-TOLERANCE/2) tag(_tag_left)
        knuckle(HR_SPLIT_KNUCKLE_TYPE_LOCK, knuckle_strength=knuckle_strength, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
      attach(TOP,BOTTOM,overlap=-TOLERANCE-BASE_UNIT) tag(_tag_right)
        knuckle(HR_SPLIT_KNUCKLE_TYPE_REGULAR, knuckle_strength=knuckle_strength, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
    }
  }

  attachable_width = get_split_connector_width(knuckle_strength);
  attachable_depth = HR_SPLIT_KNUCKLE_STRENGTH_SLIM;
  attachable_height = units * STD_UNIT_HEIGHT - TOLERANCE/2;

  attachable(anchor=anchor, spin=spin, orient=orient, size=[attachable_width, attachable_depth, attachable_height]) {
    down(attachable_height/2 - get_knuckle_height(HR_SPLIT_KNUCKLE_TYPE_REGULAR)/2)
    for ($idx = [0 : units - 1]) {
      translate([0, 0, $idx * STD_UNIT_HEIGHT]) {
          split_connector_1HU(invert = ($idx % 2 != 0));
      }
    }
    children();
  }
}


// the split lock pin threads vertically through the split_connector knuckle stack and
// locks two split panel halves together (it replaces the standard lock pin for split panels).
// it reuses the core lock pin's central tension grip (tension_shape + tension_hole) as the
// lock element of every height unit — aligned with each lock knuckle — joined by plain shaft
// segments that fill the regular knuckles above and below each grip. one tension grip is
// placed per height unit, so the pin scales with the panel height.
//
// per height unit the lock element is a full BASE_UNIT (the lock knuckle): the central tension
// grip plus one extension on each side. following the lock pin, the extension length is
//   (BASE_UNIT - tension_grip) / 2
// the shafts butt against the grip's narrow ends (they never overlap the flaring grip face),
// so every grip presents as a clean 2D wedge just like a standard lock pin.
HR_SPLIT_LOCKPIN_TENSION_HEIGHT = lockpin_prismoid_length * 2; // = BASE_UNIT - BASE_STRENGTH
// shaft from a grip end out to the pin end (extension + one regular knuckle)
HR_SPLIT_LOCKPIN_END_SHAFT = (STD_UNIT_HEIGHT - HR_SPLIT_LOCKPIN_TENSION_HEIGHT) / 2;
// shaft bridging two neighbouring grips (two extensions + two regular knuckles)
HR_SPLIT_LOCKPIN_MID_SHAFT = STD_UNIT_HEIGHT - HR_SPLIT_LOCKPIN_TENSION_HEIGHT;

// one tension grip (lock element core), with the flex slit removed. BASE_UNIT - BASE_STRENGTH tall.
module split_lockpin_grip(debug_colors=false, anchor=CENTER, spin=0, orient=UP) {
  attachable(anchor=anchor, spin=spin, orient=orient,
    size=[lockpin_width_inner, lockpin_height, HR_SPLIT_LOCKPIN_TENSION_HEIGHT]) {
    diff() {
      color(debug_colors ? HR_YELLOW : HR_CORE_SUPPORT_SECONDARY_COLOR) tension_shape();
      tag("remove") tension_hole();
    }
    children();
  }
}

// shaft end cap: the pin's outer end. TOP end is filleted + chamfered like a lock pin neck,
// the BOTTOM end stays flush so it butts against the grip.
module split_lockpin_end_cap(debug_colors=false, chamfer_enabled=true, anchor=CENTER, spin=0, orient=UP) {
  cap_fillet = lockpin_width_outer / 3;
  cap_size = [lockpin_width_outer, lockpin_height, HR_SPLIT_LOCKPIN_END_SHAFT];
  attachable(anchor=anchor, spin=spin, orient=orient, size=cap_size) {
    color(debug_colors ? HR_BLUE : HR_CORE_SUPPORT_SECONDARY_COLOR)
    if (chamfer_enabled)
      // fillet + chamfer can't share an edge, so intersect a rounded and a chamfered cuboid
      intersection() {
        cuboid(cap_size, rounding=cap_fillet, edges=[TOP + LEFT, TOP + RIGHT]);
        cuboid(cap_size, chamfer=lockpin_chamfer, edges=[FRONT, BACK], except=BOTTOM);
      }
    else
      cuboid(cap_size);
    children();
  }
}

module split_lockpin(units=1,
  anchor=CENTER, spin=0, orient=UP,
  debug_colors=false, chamfer_enabled=true) {

  assert(is_int(units) && units >= 1, "units must be a positive integer");

  total_height = units * STD_UNIT_HEIGHT;

  attachable(anchor=anchor, spin=spin, orient=orient,
    size=[lockpin_width_inner, lockpin_height, total_height]) {
    // one grip per height unit; shafts and end caps grow off each grip via attach
    zcopies(spacing=STD_UNIT_HEIGHT, n=units)
      split_lockpin_grip(debug_colors=debug_colors) {
        // outer end cap below the bottom-most grip (treated TOP end points outward/down)
        if ($idx == 0)
          attach(BOTTOM, BOTTOM)
            split_lockpin_end_cap(debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
        // above each grip: outer end cap on the top-most grip, else a bridge to the next grip
        if ($idx == units - 1)
          attach(TOP, BOTTOM)
            split_lockpin_end_cap(debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
        else
          attach(TOP, BOTTOM)
            color(debug_colors ? HR_BLUE : HR_CORE_SUPPORT_SECONDARY_COLOR)
            cuboid([lockpin_width_outer, lockpin_height, HR_SPLIT_LOCKPIN_MID_SHAFT]);
      }
    children();
  }
}


// split_connector(units=units, debug_colors=debug_colors, chamfer_enabled=enable_chamfer,knuckle_side=knuckle_side) show_anchors();

// left_half(s=STD_WIDTH_19INCH,x=-TOLERANCE/4)
// rackpanel(STD_WIDTH_19INCH,
//   debug_colors=debug_colors, chamfer_enabled=enable_chamfer,
//   ) {
//     align(BACK)
//     split_connector(units=1, knuckle_side=HR_SPLIT_KNUCKLE_SIDE_ALL,
//       debug_colors=debug_colors, chamfer_enabled=enable_chamfer);
//   }
