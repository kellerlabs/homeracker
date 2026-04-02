// HomeRacker - Sleeve Test
//
// Test file for sleeve module.

include <../lib/sleeve.scad>

// Default: single-unit sleeve
sleeve(length=1);

// Multi-unit sleeve
right(40)
sleeve(length=3);

// Tall sleeve
right(80)
sleeve(length=8);

// Debug colors enabled
right(120)
sleeve(length=3, debug_colors=true);

// Chamfer disabled
right(160)
sleeve(length=3, disable_chamfer=true);

// Custom color
right(200)
sleeve(length=3, color=HR_BLUE);
