// HomeRacker - Rack Panel
//
// Standalone rack panel for standard 10" and 19" rack mounting.

include <../lib/rackpanel.scad>

/* [General Parameters] */
// Panel width standard
panel_width_type = 1; // [1:10 Inch (254mm), 2:19 Inch (482.6mm)]
// Panel height in rack units
height_Units = 1; // [1:1:8]
// Bore hole pattern
bore_mode = 0; // [0:Default, 1:All, 2:Minimal]

/* [Debug Parameters] */
// Show distinct colors per section for easier debugging and measurement
debug_colors = false; // [false,true]
// Enable chamfering on edges
chamfer_enabled = true; // [false,true]

/* [Hidden] */
$fn = 100;

panel_width = panel_width_type == 1 ? STD_WIDTH_10INCH : STD_WIDTH_19INCH;

rackpanel(panel_width=panel_width, panel_height_units=height_Units, bore_mode=bore_mode, debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
