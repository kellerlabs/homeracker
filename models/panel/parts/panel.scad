// HomeRacker - Panel
//
// Fully customizable mounting panel.

include <../lib/panel.scad>

/* [General Parameters] */
// Panel type
panel_type = 1; // [1:Inter-Fit, 2:Full Cover]
// Panel width in HomeRacker units
units_x = 4; // [2:1:16]
// Panel height in HomeRacker units
units_y = 2; // [2:1:16]

/* [Full Cover Parameters] */
// Clearance between each panel (defaults to 0.0mm). Panel area will be reduced by this amount.
panel_clearance = 0.0; // [0:0.1:0.4]

/* [Support Contact] */
// Add protrusions on horizontal supports for direct bar contact (only effective when units_x > 2)
support_contact_x = false; // [false,true]
// Add protrusions on vertical supports for direct bar contact (only effective when units_y > 2)
support_contact_y = false; // [false,true]

/* [Debug Parameters] */
// Show distinct colors per section for easier debugging and measurement
debug_colors = false; // [false,true]
// Enable chamfering on edges
chamfer_enabled = true; // [false,true]

/* [Hidden] */
$fn = 100;

panel(units_x, units_y, panel_type=panel_type, panel_clearance=panel_clearance,
  support_contact_x=support_contact_x, support_contact_y=support_contact_y,
  debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
