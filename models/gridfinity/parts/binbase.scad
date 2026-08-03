// Gridfinity - Bin Base
// Printable bin base grid.

include <BOSL2/std.scad>
include <../../core/lib/constants.scad>
include <../lib/baseplate.scad>
include <../lib/binbase.scad>

/* [Parameters] */
// x dimensions (in multiples of 42mm)
grid_x = 1; // [1:1:10]
// y dimensions (in multiples of 42mm)
grid_y = 2; // [1:1:10]

/* [Advanced] */
topplate_thickness = 0;

/* [Hidden] */
// Optimized for 0.4mm nozzle 3D printing (allegedly according to Sonnet 4.5's research)
// Preview: Faster but still smooth
// Render: Based on typical 0.4mm nozzle capabilities
$fs = $preview ? 0.8 : 0.4;
$fa = $preview ? 6 : 2;

if(topplate_thickness > 0){
    color(HR_YELLOW)
    binbase_with_topplate(units_x=grid_x,units_y=grid_y, topplate_thickness=topplate_thickness) show_anchors();
} else {
    color(HR_YELLOW)
    binbase(units_x=grid_x,units_y=grid_y);
}
// uncomment to see how the binbase sits on a baseplate
// color(HR_WHITE)
// baseplate(grid_x, grid_y);
