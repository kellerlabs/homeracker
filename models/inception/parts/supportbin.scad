// HomeRacker - Support Bin
// Gridfinity-compatible bin for storing HomeRacker supports.

include <../lib/supportbin.scad>

/* [Parameters] */

// x dimensions (in multiples of 42mm)
grid_x = 2; // [1:1:17]
// y dimensions (in multiples of 42mm)
grid_y = 2; // [1:1:10]

/* [Advanced] */
// thickness of the dividers between cells
divider_strength = 1.2; // [1.0:0.1:3.0]
// grid style: 0 = riser (cross-shaped ridges), 1 = full (solid walls)
grid_style = 0; // [0:Riser, 1:Full]
// height of the pocket grid
height = 15; // [5:1:15]

/* [Hidden] */
// Optimized for 0.4mm nozzle 3D printing
// Preview: Faster but still smooth
// Render: Based on typical 0.4mm nozzle capabilities
$fs = $preview ? 0.8 : 0.4;
$fa = $preview ? 6 : 2;

supportbin(grid_x, grid_y, divider_strength, height=height, style=grid_style);
