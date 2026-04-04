// HomeRacker - Foot Insert Test
//
// Test file for foot module.

include <../lib/foot.scad>

// Default render
foot();

// Debug colors
right(30) foot(debug_colors=true);

// Chamfer disabled
right(60) foot(disable_chamfer=true);

// Both debug colors and chamfer disabled
right(90) foot(debug_colors=true, disable_chamfer=true);
