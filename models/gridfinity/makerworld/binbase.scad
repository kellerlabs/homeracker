include <BOSL2/std.scad>

/* [Parameters] */
// x dimensions (in multiples of 42mm)
grid_x = 1; // [1:1:10]
// y dimensions (in multiples of 42mm)
grid_y = 2; // [1:1:10]

/* [Hidden] */
TOLERANCE = 0.2;
PRINTING_LAYER_WIDTH = 0.4;
PRINTING_LAYER_HEIGHT = 0.2;
BASE_UNIT = 15;
BASE_STRENGTH = 2;
BASE_CHAMFER = 1;
LOCKPIN_HOLE_CHAMFER = 0.8;
LOCKPIN_HOLE_SIDE_LENGTH = 4;
LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION = [LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH];
LP_GRIP_STANDARD = 0;
LP_GRIP_EXTENDED = 1;
LP_GRIP_NO_GRIP = 2;
LP_NECK_EXT_NONE = 0;
LP_NECK_EXT_GRIP = 1;
LP_NECK_EXT_BOTH = 2;
LP_NECK_EXT_FOOT = 3;
LP_NECK_EXTENSION_UNIT = BASE_STRENGTH + TOLERANCE/2;
HR_YELLOW = "#f7b600";
HR_BLUE = "#0056b3";
HR_RED = "#c41e3a";
HR_GREEN = "#2d7a2e";
HR_CHARCOAL = "#333333";
HR_WHITE = "#f0f0f0";
STD_UNIT_HEIGHT = 44.45;
STD_UNIT_DEPTH = 482.6;
STD_WIDTH_10INCH = 254;
STD_WIDTH_19INCH = 482.6;
STD_MOUNT_SURFACE_WIDTH = 15.875;
STD_RACK_BORE_DISTANCE_Z = 15.875;
STD_RACK_BORE_DISTANCE_MARGIN_Z = 6.35;
tolerance = TOLERANCE;
printing_layer_width = PRINTING_LAYER_WIDTH;
printing_layer_height = PRINTING_LAYER_HEIGHT;
base_unit = BASE_UNIT;
base_strength = BASE_STRENGTH;
base_chamfer = BASE_CHAMFER;
lockpin_hole_chamfer = LOCKPIN_HOLE_CHAMFER;
lockpin_hole_side_length = LOCKPIN_HOLE_SIDE_LENGTH;
lockpin_hole_side_length_dimension = LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION;

BP_BOTTOM_LIP_SIDE_LENGTH = 36.3;
BP_BOTTOM_LIP_ROUNDING = 1.15;
BP_BOTTOM_LIP_HEIGHT = 0.7;
BP_MID_PART_SIDE_LENGTH = 37.7;
BP_MID_PART_ROUNDING = 1.85;
BP_MID_PART_HEIGHT = 1.8;
BP_TOP_PART_SIDE_LENGTH = 42;
BP_TOP_PART_ROUNDING = 4;
BP_TOP_PART_HEIGHT = 2.15;
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

GRIDFINITY_BASE_UNIT = 42;
BB_BOTTOM_LIP_SIDE_LENGTH = 35.8;
BB_BOTTOM_LIP_ROUNDING = 0.8;
BB_BOTTOM_LIP_HEIGHT = 0.8;
BB_MID_PART_SIDE_LENGTH = 37.2;
BB_MID_PART_ROUNDING = 1.6;
BB_MID_PART_HEIGHT = 1.8;
BB_TOP_PART_SIDE_LENGTH = 41.5;
BB_TOP_PART_ROUNDING = 3.75;
BB_TOP_PART_HEIGHT = 2.15;
module binbase_cell() {
  prismoid(BB_BOTTOM_LIP_SIDE_LENGTH, BB_MID_PART_SIDE_LENGTH, rounding1=BB_BOTTOM_LIP_ROUNDING, rounding2=BB_MID_PART_ROUNDING, h=BB_BOTTOM_LIP_HEIGHT)
    attach(TOP,BOTTOM) cuboid([BB_MID_PART_SIDE_LENGTH, BB_MID_PART_SIDE_LENGTH, BB_MID_PART_HEIGHT], rounding=BB_MID_PART_ROUNDING, except=[BOTTOM,TOP])
    attach(TOP,BOTTOM) prismoid(BB_MID_PART_SIDE_LENGTH, BB_TOP_PART_SIDE_LENGTH, rounding1=BB_MID_PART_ROUNDING, rounding2=BB_TOP_PART_ROUNDING, h=BB_TOP_PART_HEIGHT);
}

module binbase(units_x=1, units_y=1) {
  assert(is_int(units_x), "units_x must be an integer");
  assert(is_int(units_y), "units_y must be an integer");
  assert(units_x >= 1, "units_x must be at least 1");
  assert(units_y >= 1, "units_y must be at least 1");

  BASEBIN_HEIGHT = BB_BOTTOM_LIP_HEIGHT+BB_MID_PART_HEIGHT+BB_TOP_PART_HEIGHT-PRINTING_LAYER_HEIGHT*3;

  grid_copies(n=[units_x, units_y], spacing=GRIDFINITY_BASE_UNIT)
    binbase_cell();
}
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
binbase(grid_x, grid_y);

// uncomment to see how the binbase sits on a baseplate
// color(HR_WHITE)
// baseplate(grid_x, grid_y);
