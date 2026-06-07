// HomeRacker - Rack Panel
//
// Standalone rack panel for standard 10" and 19" rack mounting.

include <../lib/rackpanel.scad>
include <../lib/split.scad>

/* [General Parameters] */
// Panel width standard
panel_width_type = 1; // [1:10 Inch (254mm), 2:19 Inch (482.6mm), 3:Demo split (60mm)]
// Panel height in rack units
height_units = 1; // [1:1:8]
// Bore hole pattern
bore_mode = 0; // [0:Default, 1:All, 2:Minimal]

/* [Stability & Strength] */
// Panel depth (wall thickness)
panel_depth_type = 1; // [1:Regular (2mm), 2:Strong (4mm)]
// Back-side truss stiffener (flush with split-knuckle plane)
back_brace = false; // [false,true]
// Truss grid density for the back brace (only relevant if back_brace is on)
back_brace_density = "regular"; // [regular, dense]

/* [Advanced Parameters] */
// Split mode for rack panel — controls how the panel is split for assembly and viewing
split_mode = 0; // [0:Full, 1:Half]
// view mode controls which sections of the panel are visible in case of a split mode selection other than full
view_mode = 0; // [0:Assembled, 1:Half Left, 2:Half Right, 3:Exploded]

/* [Debug Parameters] */
// Show distinct colors per section for easier debugging and measurement
debug_colors = false; // [false,true]
// Enable chamfering on edges
chamfer_enabled = true; // [false,true]

/* [Hidden] */
$fn = 100;

panel_width = panel_width_type == 1 ? STD_WIDTH_10INCH :
  panel_width_type == 2 ? STD_WIDTH_19INCH :
  RP_DEMO_WIDTH;

_panel_depth = panel_depth_type == 2 ? 4 : 2;

// Density scales with height so triangles keep a consistent size across panel heights:
// regular = 1 band per unit, dense = 2 bands per unit.
_brace_rows = back_brace_density == "regular" ? max(1, height_units) :
  back_brace_density == "dense" ? max(2, 2 * height_units) :
  die(str("Invalid back_brace_density: ", back_brace_density));

rackpanel(panel_width=panel_width, panel_height_units=height_units, bore_mode=bore_mode,
  split_mode=split_mode, view_mode=view_mode,
  panel_depth=_panel_depth,
  brace_enabled=back_brace, brace_rows=_brace_rows,
  debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
