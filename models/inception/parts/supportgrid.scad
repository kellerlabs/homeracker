// HomeRacker - Support Grid
// Frame-mounted grid for organizing HomeRacker supports within a rack.

include <../lib/supportgrid.scad>

/* [Basic] */
// Width of containing homeracker frame in HomeRacker units (1 unit = 15mm)
hr_width = 11; // [15:1:17]
// Height of containing homeracker frame in HomeRacker units (1 unit = 15mm)
hr_height = 3; // [3:1:10]
// End Piece - used as stopper at the back to prevent supports from sliding too far back into the rack.
end_piece = false; // [false,true]

/* [Advanced] */
// Funnel strength of the grid (in mm). Min 2mm to avoid clashing with connectors
funnel_strength = 3; // [3.3:0.1:5]
// Depth of the Grid in HomeRacker units (longer is more stable)
grid_depth = 1; // [1:1:5]
// Mounting axis (determines whether the mounting ears are on the top/bottom (horizontal) or the sides (vertical) of the grid)
mounting_axis = 1; // [1:Vertical,2:Horizontal,3:Both]

/* [Debugging] */
// Enables debugging colorization to easier spot changes when tinkering with parameters
debug_colors = false; // [false,true]
// Makes it easier to measure dimensions
disable_chamfer = false; // [false,true]

/* [Hidden] */
$fs = $preview ? 0.8 : 0.4;
$fa = $preview ? 6 : 2;

supportgrid(hr_width=hr_width, hr_height=hr_height, end_piece=end_piece,
  funnel_strength=funnel_strength, grid_depth=grid_depth, mounting_axis=mounting_axis,
  debug_colors=debug_colors, disable_chamfer=disable_chamfer);
