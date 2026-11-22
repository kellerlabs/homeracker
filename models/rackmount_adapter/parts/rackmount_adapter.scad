// HomeRacker - Rackmount Adapter
// Bridges a vertical HomeRacker support to a standard rack rail of any inch width, one adapter per rack side,
// closed at the top and bottom by end covers.

include <../lib/end_cover.scad>

/* [General] */
// What to show: the assembled rack front, or a single part to print
part = "assembly";  // [assembly, adapter, end cover top, end cover bottom]
// Width of the rack in full inches
inches = 10;  // [2:1:20]
// Height in standard rack units (1U = 44.45 mm)
height_units = 1;  // [1:1:10]
// Rack side of a single adapter
side = "left";  // [left, right]

/* [Debug Parameters] */
debug_colors = false;     // [false,true]
disable_chamfer = false;  // [false,true]
debug_anchors = false;    // [false,true]

/* [Hidden] */
$fn = 100;

module adapter(adapter_side) {
  rackmount_adapter(rackwidth = inches, height_units = height_units, side = adapter_side,
    debug_colors = debug_colors, disable_chamfer = disable_chamfer
  )
    children();
}

module cover(type) {
  end_cover(rackwidth = inches, height_units = height_units, type = type,
    debug_colors = debug_colors, disable_chamfer = disable_chamfer
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
} else if (part == "adapter") {
  adapter(side == "right" ? RIGHT : LEFT)
    if (debug_anchors) show_anchors();
} else {
  cover(part == "end cover top" ? END_COVER_TOP : END_COVER_BOTTOM)
    if (debug_anchors) show_anchors();
}

echo("inches: ", inches);
echo("mm: ", inches * 25.4);
echo("hr units: ", get_hr_units_by_inches(inches));
echo("gapfill: ", get_adapter_gapfill(inches));
echo("hr to std height diff: ", get_hr_to_std_height_diff(height_units));
