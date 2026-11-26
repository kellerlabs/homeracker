// HomeRacker - Rackmount Adapter
// Bridges a vertical HomeRacker support to a standard rack rail of any inch width, one adapter per rack side,
// closed at the top and bottom by end covers.

include <../lib/end_cover.scad>

/* [General] */
// What to show: the assembled rack front, or a print plate
part = "assembly";  // [assembly, adapters, end covers]
// Width of the rack in full inches
inches = 10;  // [2:1:20]
// Height in standard rack units (1U = 44.45 mm)
height_units = 1;  // [1:1:10]

/* [Debug Parameters] */
debug_colors = false;     // [false,true]
disable_chamfer = false;  // [false,true]
debug_anchors = false;    // [false,true]

/* [Hidden] */
$fn = 100;
// gap between parts on a print plate
plate_gap = 5;  // in mm

module adapter(adapter_side, anchor = CENTER, orient = UP) {
  rackmount_adapter(rackwidth = inches, height_units = height_units, side = adapter_side,
    debug_colors = debug_colors, disable_chamfer = disable_chamfer, anchor = anchor, orient = orient
  )
    children();
}

module cover(type, anchor = CENTER, orient = UP) {
  end_cover(rackwidth = inches, height_units = height_units, type = type,
    debug_colors = debug_colors, disable_chamfer = disable_chamfer, anchor = anchor, orient = orient
  )
    children();
}

if (part == "assembly") {
  // left adapter, both end covers in its docks, the right adapter on the top cover's other end
  adapter(LEFT) {
    if (debug_anchors) show_anchors();
    attach("end_cover_top", "end_cover_left") cover(END_COVER_TOP)
      attach("end_cover_right", "end_cover_top") adapter(RIGHT);
    attach("end_cover_bottom", "end_cover_left") cover(END_COVER_BOTTOM);
  }
} else if (part == "adapters") {
  // both adapters front face down, side by side
  adapter_width = mount_bridge_width + get_mount_width_total(inches);
  xdistribute(spacing = plate_gap, sizes = [adapter_width, adapter_width]) {
    adapter(LEFT, anchor = FRONT, orient = FRONT)
      if (debug_anchors) show_anchors();
    adapter(RIGHT, anchor = FRONT, orient = FRONT)
      if (debug_anchors) show_anchors();
  }
} else {
  // both end covers inner face down, the top cover in front, the bottom cover flipped behind it
  cover_depth = get_connector_cover_depth();
  // the covers' inner face sits TOLERANCE / 2 inside their attachment box
  down(TOLERANCE / 2) ydistribute(spacing = plate_gap, sizes = [cover_depth, cover_depth]) {
    cover(END_COVER_TOP, anchor = BOTTOM)
      if (debug_anchors) show_anchors();
    cover(END_COVER_BOTTOM, anchor = TOP, orient = DOWN)
      if (debug_anchors) show_anchors();
  }
}

echo("inches: ", inches);
echo("mm: ", inches * 25.4);
echo("hr units: ", get_hr_units_by_inches(inches));
echo("gapfill: ", get_adapter_gapfill(inches));
echo("hr to std height diff: ", get_hr_to_std_height_diff(height_units));
