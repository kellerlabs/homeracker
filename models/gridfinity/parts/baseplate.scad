// Gridfinity - Baseplate Example
// This file demonstrates how to use the baseplate module from the Gridfinity library.

include <BOSL2/std.scad>
include <../../core/lib/constants.scad>
include <../lib/baseplate.scad>

/* [Parameters] */
// x dimensions (in multiples of 42mm)
grid_x = 1;  // [1:1:10]
// y dimensions (in multiples of 42mm)
grid_y = 2;  // [1:1:10]

/* [Hidden] */
// Optimized for 0.4mm nozzle 3D printing (allegedly according to Sonnet 4.5's research)
// Preview: Faster but still smooth
// Render: Based on typical 0.4mm nozzle capabilities
$fs = $preview ? 0.8 : 0.4;
$fa = $preview ? 6 : 2;
// I normally use $fn = 100 for good results, but it's really performance heavy
// when being used in multiples (like here in a grid).
// The Makerworld PMM cannot handle that well (only up to 6x6 which might be too little for some folks).
// $fn = $preview ? 32 : 100;  // Fixed segments (less adaptive and friggin performance heavy)

color(HR_YELLOW)
  baseplate(grid_x, grid_y);
