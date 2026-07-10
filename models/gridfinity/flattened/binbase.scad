include <BOSL2/std.scad>

/* [Parameters] */
// x dimensions (in multiples of 42mm)
grid_x = 1; // [1:1:10]
// y dimensions (in multiples of 42mm)
grid_y = 2; // [1:1:10]

/* [Hidden] */
// --- from constants.scad ---
HR_YELLOW = "#f7b600";
GRIDFINITY_BASE_UNIT = 42;
GRIDFINITY_BINBASE_SUBTRACTOR = 0.5;
GRIDFINITY_BB_BOTTOM_LIP_SIDE_LENGTH = 35.8;
GRIDFINITY_BB_BOTTOM_LIP_ROUNDING = 0.8;
GRIDFINITY_BB_BOTTOM_LIP_HEIGHT = 0.8;
GRIDFINITY_BB_MID_PART_SIDE_LENGTH = 37.2;
GRIDFINITY_BB_MID_PART_ROUNDING = 1.6;
GRIDFINITY_BB_MID_PART_HEIGHT = 1.8;
GRIDFINITY_BB_TOP_PART_SIDE_LENGTH = 41.5;
GRIDFINITY_BB_TOP_PART_ROUNDING = 3.75;
GRIDFINITY_BB_TOP_PART_HEIGHT = 2.15;
GRIDFINITY_BB_HEIGHT = GRIDFINITY_BB_BOTTOM_LIP_HEIGHT + GRIDFINITY_BB_MID_PART_HEIGHT + GRIDFINITY_BB_TOP_PART_HEIGHT;
// Optimized for 0.4mm nozzle 3D printing (allegedly according to Sonnet 4.5's research)
// Preview: Faster but still smooth
// Render: Based on typical 0.4mm nozzle capabilities
$fs = $preview ? 0.8 : 0.4;
$fa = $preview ? 6 : 2;
module binbase_cell() {
  prismoid(GRIDFINITY_BB_BOTTOM_LIP_SIDE_LENGTH, GRIDFINITY_BB_MID_PART_SIDE_LENGTH, rounding1=GRIDFINITY_BB_BOTTOM_LIP_ROUNDING, rounding2=GRIDFINITY_BB_MID_PART_ROUNDING, h=GRIDFINITY_BB_BOTTOM_LIP_HEIGHT)
    attach(TOP,BOTTOM) cuboid([GRIDFINITY_BB_MID_PART_SIDE_LENGTH, GRIDFINITY_BB_MID_PART_SIDE_LENGTH, GRIDFINITY_BB_MID_PART_HEIGHT], rounding=GRIDFINITY_BB_MID_PART_ROUNDING, except=[BOTTOM,TOP])
    attach(TOP,BOTTOM) prismoid(GRIDFINITY_BB_MID_PART_SIDE_LENGTH, GRIDFINITY_BB_TOP_PART_SIDE_LENGTH, rounding1=GRIDFINITY_BB_MID_PART_ROUNDING, rounding2=GRIDFINITY_BB_TOP_PART_ROUNDING, h=GRIDFINITY_BB_TOP_PART_HEIGHT);
}
module binbase(units_x=1, units_y=1, anchor=CENTER, spin=0, orient=UP) {
  assert(is_int(units_x), "units_x must be an integer");
  assert(is_int(units_y), "units_y must be an integer");
  assert(units_x >= 1, "units_x must be at least 1");
  assert(units_y >= 1, "units_y must be at least 1");

  basebin_dimensions = [GRIDFINITY_BB_TOP_PART_SIDE_LENGTH*units_x - GRIDFINITY_BINBASE_SUBTRACTOR, GRIDFINITY_BB_TOP_PART_SIDE_LENGTH*units_y - GRIDFINITY_BINBASE_SUBTRACTOR, GRIDFINITY_BB_HEIGHT];

  attachable(anchor, spin, orient, size=basebin_dimensions){
    grid_copies(n=[units_x, units_y], spacing=GRIDFINITY_BASE_UNIT)
      binbase_cell();
    children();
  }
}

color(HR_YELLOW)
binbase(grid_x, grid_y);

// uncomment to see how the binbase sits on a baseplate
// color(HR_WHITE)
// baseplate(grid_x, grid_y);
