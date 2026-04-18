include <BOSL2/std.scad>

/* [Parameters] */
// x dimensions (in multiples of 42mm)
grid_x = 1; // [1:1:10]
// y dimensions (in multiples of 42mm)
grid_y = 2; // [1:1:10]

/* [Hidden] */
// --- from constants.scad ---
PRINTING_LAYER_HEIGHT = 0.2;
HR_YELLOW = "#f7b600";
GRIDFINITY_BASE_UNIT = 42;
// --- from baseplate.scad ---
BP_BOTTOM_LIP_SIDE_LENGTH = 36.3;
BP_BOTTOM_LIP_ROUNDING = 1.15;
BP_BOTTOM_LIP_HEIGHT = 0.7;
BP_MID_PART_SIDE_LENGTH = 37.7;
BP_MID_PART_ROUNDING = 1.85;
BP_MID_PART_HEIGHT = 1.8;
BP_TOP_PART_SIDE_LENGTH = GRIDFINITY_BASE_UNIT;
BP_TOP_PART_ROUNDING = 4;
BP_TOP_PART_HEIGHT = 2.15;
// Optimized for 0.4mm nozzle 3D printing (allegedly according to Sonnet 4.5's research)
// Preview: Faster but still smooth
// Render: Based on typical 0.4mm nozzle capabilities
$fs = $preview ? 0.8 : 0.4;
$fa = $preview ? 6 : 2;
// I normally use $fn = 100 for good results, but it's really performance heavy
// when being used in multiples (like here in a grid).
// The Makerworld PMM cannot handle that well (only up to 6x6 which might be too little for some folks).
// $fn = $preview ? 32 : 100;  // Fixed segments (less adaptive and friggin performance heavy)
module baseplate_cutout() {
  prismoid(BP_BOTTOM_LIP_SIDE_LENGTH, BP_MID_PART_SIDE_LENGTH, rounding1=BP_BOTTOM_LIP_ROUNDING, rounding2=BP_MID_PART_ROUNDING, h=BP_BOTTOM_LIP_HEIGHT)
    attach(TOP,BOTTOM) cuboid([BP_MID_PART_SIDE_LENGTH, BP_MID_PART_SIDE_LENGTH, BP_MID_PART_HEIGHT], rounding=BP_MID_PART_ROUNDING, except=[BOTTOM,TOP])
    attach(TOP,BOTTOM) prismoid(BP_MID_PART_SIDE_LENGTH, BP_TOP_PART_SIDE_LENGTH, rounding1=BP_MID_PART_ROUNDING, rounding2=BP_TOP_PART_ROUNDING, h=BP_TOP_PART_HEIGHT);
}
module baseplate(units_x=1, units_y=1) {
  assert(is_int(units_x), "units_x must be an integer");
  assert(is_int(units_y), "units_y must be an integer");
  assert(units_x >= 1, "units_x must be at least 1");
  assert(units_y >= 1, "units_y must be at least 1");

  BASEPLATE_HEIGHT = BP_BOTTOM_LIP_HEIGHT+BP_MID_PART_HEIGHT+BP_TOP_PART_HEIGHT-PRINTING_LAYER_HEIGHT*3;
  baseplate_dimensions = [BP_TOP_PART_SIDE_LENGTH*units_x, BP_TOP_PART_SIDE_LENGTH*units_y, BASEPLATE_HEIGHT];

  difference() {

    cuboid(baseplate_dimensions, rounding=BP_TOP_PART_ROUNDING, except=[TOP,BOTTOM], anchor=BOTTOM);

    grid_copies(n=[units_x, units_y], spacing=BP_TOP_PART_SIDE_LENGTH)
      baseplate_cutout();
  }
}

color(HR_YELLOW)
baseplate(grid_x, grid_y);
