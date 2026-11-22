// KellerLab Essentials - Print Bed Fit Test
//
// Asserts print_fit against closed-form cases and renders the fitted part on its bed.

include <BOSL2/std.scad>
include <../lib/print_bed.scad>

// HomeRacker support width and unit length in mm
SUPPORT_WIDTH = 15;

function _approx(a, b, eps = 0.001) = abs(a - b) < eps;

// Square bed: diagonal placement at 45 degrees gives side * sqrt(2) - width
assert(_approx(max_print_length([256, 256], 15), 256 * sqrt(2) - 15), "square bed diagonal length");
assert(_approx(print_fit([256, 256], 15)[1], 45), "square bed diagonal angle");

// A part wider than the bed's sides still fits diagonally while it is short enough
assert(_approx(max_print_length([256, 256], 300), 256 * sqrt(2) - 300), "wide part fits diagonally");

// A width just below the bed diagonal fits within a narrow angle range only
assert(max_print_length([200, 300], 360) > 0.3, "narrow feasible angle range");

// The diagonal peak beats straight placement along Y by a fraction of a millimetre
assert(_approx(print_angle([200, 300], 71.61, 300.1), 63, 0.1), "interior peak next to the 90 degree end");

// Straight placement wins when the part is wide relative to the bed
assert(print_fit([100, 300], 150) == [100, 0], "straight placement along X");

// Nothing fits: length 0 and no angle
assert(print_fit([256, 256], 400) == [0, undef], "part wider than the bed diagonal");

// Swapping the bed axes keeps the length and mirrors the angle
assert(_approx(max_print_length([320, 325], 15), max_print_length([325, 320], 15)), "axis swap keeps length");
assert(_approx(print_fit([320, 325], 15)[1], 90 - print_fit([325, 320], 15)[1]), "axis swap mirrors angle");

// The angle reproduces the length: the part's bounding box touches both bed edges
_fit = print_fit([325, 320], 15);
assert(_approx(_fit[0] * cos(_fit[1]) + 15 * sin(_fit[1]), 325), "fit touches the X edge");
assert(_approx(_fit[0] * sin(_fit[1]) + 15 * cos(_fit[1]), 320), "fit touches the Y edge");

// print_angle prefers straight placement and falls back to the diagonal
assert(print_angle([256, 256], 15, 250) == 0, "fits straight along X");
assert(print_angle([200, 300], 15, 250) == 90, "fits straight along Y");
assert(_approx(print_angle([256, 256], 15, 340), 45), "fits diagonally");
assert(is_undef(print_angle([256, 256], 15, 350)), "too long for the diagonal");
assert(print_angle([256, 256], 250, 15) == 0, "width and length are interchangeable");

// Presets and HomeRacker support lengths in base units
assert(bed_size("bambu_x1c") == [256, 256], "preset lookup");
assert(floor(max_print_length(bed_size("bambu_x1c"), SUPPORT_WIDTH) / SUPPORT_WIDTH) == 23, "X1C fits a 23 unit support");
assert(floor(max_print_length(bed_size("bambu_h2c"), SUPPORT_WIDTH) / SUPPORT_WIDTH) == 28, "H2C fits a 28 unit support");
assert(floor(max_print_length(bed_size("bambu_h2c_single"), SUPPORT_WIDTH) / SUPPORT_WIDTH) == 29, "H2C left nozzle fits a 29 unit support");

// Visual: the longest support on the H2C's left nozzle area
_bed = bed_size("bambu_h2c_single");
_part = print_fit(_bed, SUPPORT_WIDTH);
color("gray") cube([_bed[0], _bed[1], 1]);
color("gold") up(1) right(SUPPORT_WIDTH * sin(_part[1])) zrot(_part[1]) cube([_part[0], SUPPORT_WIDTH, SUPPORT_WIDTH]);
