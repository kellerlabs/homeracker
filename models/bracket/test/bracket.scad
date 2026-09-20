// HomeRacker - Bracket Test
//
// Test file for bracket module.

include <../lib/bracket.scad>

// Default: grid-aligned device, deep enough for two mount columns
bracket(device_width=90, device_depth=99, device_height=25.5);

// Off-grid width, the wings widen to reach the nearest supports
right(200)
bracket(device_width=103.7, device_depth=99, device_height=25.5);

// Shallow device, falls back to a single mount column
right(400)
bracket(device_width=90, device_depth=30, device_height=25.5);

// Forced single column on a deep device
right(600)
bracket(device_width=90, device_depth=200, device_height=25.5, mount_columns=1);

// Offset wings, as used behind a front panel
right(850)
bracket(device_width=90, device_depth=200, device_height=25.5, mount_offset_y=34);

// Tall device with deep side walls
fwd(300)
bracket(device_width=90, device_depth=99, device_height=120, strength_sides=60);

// Top plate reaching its inward limit, which drops the window chamfer
fwd(300) right(200)
bracket(device_width=90, device_depth=99, device_height=25.5, strength_top=50);

// Minimal shell, both strengths at their floor
fwd(300) right(400)
bracket(device_width=90, device_depth=99, device_height=25.5,
  strength_top=BASE_STRENGTH, strength_sides=BASE_STRENGTH);

// Debug colors enabled
fwd(300) right(600)
bracket(device_width=90, device_depth=99, device_height=25.5, debug_colors=true);

// Chamfer disabled
fwd(300) right(800)
bracket(device_width=90, device_depth=99, device_height=25.5, disable_chamfer=true);

// Custom color
fwd(600)
bracket(device_width=90, device_depth=99, device_height=25.5, color=HR_BLUE);

// Sub-modules on their own
fwd(600) right(200)
bracket_shell(90.2, 99.2, 25.5, 7.5, 7.5, 103.2);

fwd(600) right(400)
bracket_mount_pair(90.2, 25.5);

// Boundaries the assertions guard, each at the value that still passes
fwd(600) right(600)
bracket(device_width=90, device_depth=99, device_height=BRACKET_MIN_DEVICE_HEIGHT);

fwd(600) right(800)
bracket(device_width=90, device_depth=BRACKET_MIN_DEVICE_DEPTH, device_height=25.5);

fwd(850)
bracket(device_width=90, device_depth=40.2, device_height=25.5,
  mount_offset_y=40.2 - BRACKET_MIN_DEVICE_DEPTH);

fwd(850) right(200)
bracket(device_width=90, device_depth=45, device_height=25.5, mount_columns=2);
