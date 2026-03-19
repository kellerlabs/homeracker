// HomeRacker - Lock Pin Test
//
// Test file for lock pin module.

// Use the main homeracker library file
include <../main.scad>

// Test all neck extension types
for (i = [0:3]) {
  translate([i * 20, 0, 0])
  lockpin(grip_type=LP_GRIP_STANDARD, neck_extension=i);
}
