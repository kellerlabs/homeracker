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
units_y = 3; // [2:1:16]

/* [Full Cover Parameters] */
// Clearance between each panel (defaults to 0.0mm). Panel area will be reduced by this amount.
panel_clearance = 0.0; // [0:0.1:0.4]

/* [Mount Surfaces] */
// Full-height corner mounts with lockpin holes (false = contour only)
corner_mounts = true; // [false,true]
// Mount plate on north (back) edge (only effective when units_x > 2)
mount_north = true; // [false,true]
// Mount plate on south (front) edge (only effective when units_x > 2)
mount_south = true; // [false,true]
// Mount plate on east (right) edge (only effective when units_y > 2)
mount_east = true; // [false,true]
// Mount plate on west (left) edge (only effective when units_y > 2)
mount_west = true; // [false,true]

/* [Debug Parameters] */
// Show distinct colors per section for easier debugging and measurement
debug_colors = false; // [false,true]
// Enable chamfering on edges
chamfer_enabled = true; // [false,true]

/* [Hidden] */
$fn = 100;

panel(units_x, units_y, panel_type=panel_type, panel_clearance=panel_clearance,
  corner_mounts=corner_mounts, mount_north=mount_north, mount_south=mount_south,
  mount_east=mount_east, mount_west=mount_west,
  debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
