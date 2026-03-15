// HomeRacker - Lock Pin Test
//
// Test file for lock pin module.

// Use the main homeracker library file
include <../main.scad>

grip_type = LP_GRIP_STANDARD;
neck_extension = LP_NECK_EXT_BOTH;
lockpin(grip_type=grip_type, neck_extension=neck_extension);
