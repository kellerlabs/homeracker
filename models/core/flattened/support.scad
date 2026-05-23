include <BOSL2/std.scad>

/* [Parameters] */

// The length (Y-axis) of the support in base units.
units = 3; // [1:1:50]

// Add x holes
x_holes = false;

// Support width (15 = standard, 13 = truss-ready narrow)
width = 15; // [13, 15]

/* [Debug Parameters] */
debug_colors = false; // If true, uses bright colors to visualize different features (e.g. holes, main body) for testing purposes.
disable_chamfer = false; // If true, disables chamfered edges for debugging and testing.

/* [Hidden] */
// --- from constants.scad ---
PRINTING_LAYER_WIDTH = 0.4;
BASE_UNIT = 15;
BASE_CHAMFER = 1;
HR_SUPPORT_WIDTH_STD = BASE_UNIT;
HR_SUPPORT_WIDTH_TRUSS = 13;
LOCKPIN_HOLE_CHAMFER = 0.8;
LOCKPIN_HOLE_SIDE_LENGTH = 4;
LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION = [LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH];
HR_YELLOW = "#f7b600";
HR_BLUE = "#0056b3";
HR_RED = "#c41e3a";
// --- from support.scad ---
HR_CORE_SUPPORT_PRIMARY_COLOR = HR_YELLOW;
$fn = 100;

// --- Examples ---

// Example 1: Create a default support (uses default units and x_holes)
// support();

// Example 2: Create a support with 5 units and no x holes
// support(units=5, x_holes=false);

// Example 3: Create a narrow truss-ready support
// support(units=3, width=HR_SUPPORT_WIDTH_TRUSS);

// Example 4: Create a support with units, x_holes, and width as set above
module support(units=3, x_holes=false, width=HR_SUPPORT_WIDTH_STD,
    debug_colors=false, disable_chamfer=false,
    anchor=CENTER, spin=0, orient=UP) {

    assert(width == HR_SUPPORT_WIDTH_STD || width == HR_SUPPORT_WIDTH_TRUSS,
        "width must be HR_SUPPORT_WIDTH_STD (15) or HR_SUPPORT_WIDTH_TRUSS (14)");
    assert(!(width == HR_SUPPORT_WIDTH_TRUSS && x_holes),
        "x_holes not supported with truss width");

    hole_x_offset = (width == HR_SUPPORT_WIDTH_TRUSS) ? BASE_UNIT/2 - width/2 : 0;
    support_dimensions = [width, BASE_UNIT*units, BASE_UNIT];
    attachable(anchor=anchor, spin=spin, orient=orient, size=support_dimensions) {
        difference() {

            color(debug_colors ? HR_BLUE : HR_CORE_SUPPORT_PRIMARY_COLOR)
            cuboid(support_dimensions, chamfer=disable_chamfer ? 0 : BASE_CHAMFER);

            translate([hole_x_offset, 0, 0])
            ycopies(spacing=BASE_UNIT, n=units) {
                color(debug_colors ? HR_RED : HR_CORE_SUPPORT_PRIMARY_COLOR) lockpin_hole_support();
            }
            if (x_holes) {
                ycopies(spacing=BASE_UNIT, n=units) {
                    color(debug_colors ? HR_RED : HR_CORE_SUPPORT_PRIMARY_COLOR) rotate([0,90,0]) lockpin_hole_support();
                }
            }
        }
        children();
    }
}
module lockpin_hole_support() {
    lock_pin_center_side = LOCKPIN_HOLE_SIDE_LENGTH + PRINTING_LAYER_WIDTH*2;
    lock_pin_center_dimension = [lock_pin_center_side, lock_pin_center_side];

    lock_pin_outer_side = LOCKPIN_HOLE_SIDE_LENGTH + LOCKPIN_HOLE_CHAMFER*2;
    lock_pin_outer_dimension = [lock_pin_outer_side, lock_pin_outer_side];

    lock_pin_prismoid_inner_length = BASE_UNIT/2 - LOCKPIN_HOLE_CHAMFER;
    lock_pin_prismoid_outer_length = LOCKPIN_HOLE_CHAMFER;

    module hole_half() {
        union() {
            prismoid(size1=lock_pin_center_dimension, size2=LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION, h=lock_pin_prismoid_inner_length);
            translate([0, 0, lock_pin_prismoid_inner_length]) {
                prismoid(size1=LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION, size2=lock_pin_outer_dimension, h=lock_pin_prismoid_outer_length);
            }
        }
    }

    hole_half();

    mirror([0, 0, 1]) {
        hole_half();
    }
}

support(units=units, x_holes=x_holes, width=width, debug_colors=debug_colors, disable_chamfer=disable_chamfer);
