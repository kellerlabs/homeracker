// HomeRacker - Keystone Test
//
// Test file for keystone module — exercises all rotation angles,
// label variants, and panel_depth configurations.

include <../lib/keystone.scad>

// Default: keystone_full at 0° rotation
keystone_full();

// 90° rotation with labels
right(30)
keystone_full(yrot=90, add_label_slots=true, show_label=true);

// 180° rotation, thicker panel
right(60)
keystone_full(yrot=180, panel_depth=BASE_UNIT);

// 270° rotation, no labels
right(95)
keystone_full(yrot=270, add_label_slots=false);

// Debug colors enabled
right(125)
keystone_full(yrot=0, debug_colors=true, show_label=true);

// Standalone label plate
right(155)
label_plate(yrot=0);

// Demo panel
right(185)
keystone_demo_panel(yrot=90, panel_depth=15);
