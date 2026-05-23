// HomeRacker - Truss Collar Test
//
// Test file for truss_collar module.

include <../lib/truss_collar.scad>

// Default render (4 units)
truss_collar(units=4);

// Longer variant
right(40) truss_collar(units=6);

// Debug colors
right(80) truss_collar(units=4, debug_colors=true);
