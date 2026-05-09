// HomeRacker - Panel Test
//
// Test file for panel module.

include <../lib/panel.scad>

// Default: 4x2 interfit panel
panel(units_x=4, units_y=2, chamfer_enabled=true);

// Minimum size: 2x2
right(80) panel(units_x=2, units_y=2, chamfer_enabled=true);

// Tall panel with vertical mount plates: 4x4
right(160) panel(units_x=4, units_y=4, chamfer_enabled=true);

// Full cover panel
right(260) panel(units_x=4, units_y=2, panel_type=HR_PANEL_TYPE_FULLCOVER, chamfer_enabled=true);

// Full cover with clearance
right(360) panel(units_x=4, units_y=2, panel_type=HR_PANEL_TYPE_FULLCOVER, panel_clearance=0.2, chamfer_enabled=true);

// Debug colors
right(460) panel(units_x=4, units_y=4, debug_colors=true, chamfer_enabled=true);

// No chamfer
right(560) panel(units_x=4, units_y=2, chamfer_enabled=false);
