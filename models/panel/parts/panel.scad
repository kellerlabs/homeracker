// HomeRacker - Panel
//
// Fully customizable mounting panel.

include <../lib/panel.scad>

/* [General Parameters] */
// Panel type
panel_type = 1; // [1:Interfit, 2:Full Cover]
// Panel width in HomeRacker units
units_x = 4; // [2:1:10]
// Panel height in HomeRacker units
units_y = 2; // [2:1:10]

/* [Full Cover Parameters] */
// Clearance between each panel (defaults to 0.0mm). Panel area will be reduced by this amount.
panel_clearance = 0.0; // [0:0.1:0.4]

/* [Debug Parameters] */
// Show distinct colors per section for easier debugging and measurement
debug_colors = false; // [false,true]
// Enable chamfering on edges
chamfer_enabled = true; // [false,true]

/* [Hidden] */
$fn = 100;

panel(units_x, units_y, panel_type=panel_type, panel_clearance=panel_clearance,
  debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
