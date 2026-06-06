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
// Panel depth (wall thickness)
panel_depth_type = 1; // [1:Regular (2mm), 2:Strong (4mm)]

/* [Advanced Parameters] */
// Split mode for rack panel — controls how the panel is split for assembly and viewing
split_mode = 0; // [0:Full, 1:Half]
// view mode controls which sections of the panel are visible in case of a split mode selection other than full
view_mode = 0; // [0:Assembly (all), 1:Half Left, 2:Half Right]
// split connector strength (only relevant if split_mode is not full) — controls the width of the connector between split sections, which affects strength and ease of assembly
split_connector_strength = "slim"; // [slim, strong]

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

_split_connector_strength = split_connector_strength == "slim" ? HR_SPLIT_KNUCKLE_STRENGTH_SLIM :
  split_connector_strength == "strong" ? HR_SPLIT_KNUCKLE_STRENGTH_BASE :
  die(str("Invalid split_connector_strength: ", split_connector_strength));

_panel_depth = panel_depth_type == 2 ? 4 : 2;

rackpanel(panel_width=panel_width, panel_height_units=height_units, bore_mode=bore_mode,
  split_mode=split_mode, view_mode=view_mode, split_connector_strength=_split_connector_strength,
  panel_depth=_panel_depth,
  debug_colors=debug_colors, chamfer_enabled=chamfer_enabled);
