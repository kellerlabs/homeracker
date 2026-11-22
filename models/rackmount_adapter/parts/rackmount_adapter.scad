// HomeRacker - Rackmount Adapter
// Bridges a vertical HomeRacker support to a standard rack rail of any inch width, one adapter per rack side.

include <../lib/rackmount_adapter.scad>

/* [General] */
// Width of the rack in full inches
inches = 10;  // [2:1:20]
// Height in standard rack units (1U = 44.45 mm)
height_units = 1;  // [1:1:10]
// Rack side the adapter mounts on
side = "left";  // [left, right]

/* [Debug Parameters] */
debug_colors = false;     // [false,true]
disable_chamfer = false;  // [false,true]
debug_anchors = false;    // [false,true]

/* [Hidden] */
$fn = 100;

rackmount_adapter(rackwidth = inches, height_units = height_units, side = side == "right" ? RIGHT : LEFT,
  debug_colors = debug_colors, disable_chamfer = disable_chamfer
)
  if (debug_anchors) show_anchors();

echo("inches: ", inches);
echo("mm: ", inches * 25.4);
echo("hr units: ", get_hr_units_by_inches(inches));
echo("gapfill: ", get_adapter_gapfill(inches));
echo("hr to std height diff: ", get_hr_to_std_height_diff(height_units));
