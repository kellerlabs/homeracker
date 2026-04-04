// HomeRacker - Lock Pin Release Variants
//
// This is an opinionated collection of useful lock pin variants for
// export and release. Creates a grid pattern of lock pins for efficient printing.

include <../main.scad>

/* [General] */
grid = 5; // Total number of lock pins to create

// Type of grip for the lock pin
grip_type = 0; // [0:Standard, 1:Extended, 2:No Grip]

// Neck extension mode
neck_extension = 0; // [0:None, 1:Neck Side, 2:Both Sides]

/* [Hidden] */
$fn = 100;

module lockpins_grid(grid=10, grip_type=LP_GRIP_STANDARD, neck_extension=LP_NECK_EXT_NONE) {
    ext = neck_extension >= LP_NECK_EXT_NECK ? LP_NECK_EXTENSION_UNIT : 0;
    front_ext = neck_extension >= LP_NECK_EXT_BOTH ? LP_NECK_EXTENSION_UNIT : 0;
    spacing = [ grip_width + PRINTING_LAYER_WIDTH * 2, BASE_UNIT + BASE_STRENGTH * 2 + TOLERANCE + PRINTING_LAYER_WIDTH * 2 + grip_base_length + ext + front_ext];
    grid_copies(spacing, n=grid) {
        color(HR_YELLOW)
        lockpin(grip_type=grip_type, neck_extension=neck_extension);
    }
}

lockpins_grid(grid=grid, grip_type=grip_type, neck_extension=neck_extension);
