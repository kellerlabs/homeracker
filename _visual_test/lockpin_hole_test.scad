include <../models/core/lib/lockpin.scad>

// Test 1: Both chamfers (default)
translate([0, 0, 0]) lockpin_hole(depth=15);

// Test 2: Top chamfer only
translate([10, 0, 0]) lockpin_hole(depth=15, chamfer_bottom=false);

// Test 3: No chamfer
translate([20, 0, 0]) lockpin_hole(depth=15, chamfer_top=false, chamfer_bottom=false);

// Test 4: Bottom chamfer only
translate([30, 0, 0]) lockpin_hole(depth=15, chamfer_top=false);
