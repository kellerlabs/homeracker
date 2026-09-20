// HomeRacker - Bracket Test
//
// Test file for bracket module.

include <../lib/bracket.scad>

// Layout grid, wide and deep enough to keep the largest case below clear of its neighbours
COL = 250;
ROW = 350;

// Dimensions bracket() hands down to the sub-modules, derived rather than spelled out
// so the direct sub-module calls keep matching bracket() if the core constants move.
SUB_DEVICE_WIDTH = 90 + TOLERANCE;
SUB_DEVICE_DEPTH = 99 + TOLERANCE;
SUB_OUTER_DEPTH = SUB_DEVICE_DEPTH + BASE_STRENGTH*2;

// Row 1: mount column behavior

// Default: grid-aligned device, deep enough for two mount columns
bracket(device_width=90, device_depth=99, device_height=25.5);

// Off-grid width, the wings widen to reach the nearest supports
right(COL)
bracket(device_width=103.7, device_depth=99, device_height=25.5);

// Shallow device, falls back to a single mount column
right(COL*2)
bracket(device_width=90, device_depth=30, device_height=25.5);

// Forced single column on a deep device
right(COL*3)
bracket(device_width=90, device_depth=200, device_height=25.5, mount_columns=1);

// Offset wings, as used behind a front panel
right(COL*4)
bracket(device_width=90, device_depth=200, device_height=25.5, mount_offset_y=34);

// Row 2: shell behavior and debug toggles

// Tall device with deep side walls
fwd(ROW)
bracket(device_width=90, device_depth=99, device_height=120, strength_sides=60);

// Top plate reaching its inward limit, which drops the window chamfer
fwd(ROW) right(COL)
bracket(device_width=90, device_depth=99, device_height=25.5, strength_top=50);

// Minimal shell, both strengths at their floor
fwd(ROW) right(COL*2)
bracket(device_width=90, device_depth=99, device_height=25.5,
  strength_top=BASE_STRENGTH, strength_sides=BASE_STRENGTH);

// Debug colors enabled
fwd(ROW) right(COL*3)
bracket(device_width=90, device_depth=99, device_height=25.5, debug_colors=true);

// Chamfer disabled
fwd(ROW) right(COL*4)
bracket(device_width=90, device_depth=99, device_height=25.5, disable_chamfer=true);

// Row 3: sub-modules on their own

// Custom color
fwd(ROW*2)
bracket(device_width=90, device_depth=99, device_height=25.5, color=HR_BLUE);

fwd(ROW*2) right(COL)
bracket_shell(SUB_DEVICE_WIDTH, SUB_DEVICE_DEPTH, 25.5,
  BRACKET_DEFAULT_STRENGTH, BRACKET_DEFAULT_STRENGTH, SUB_OUTER_DEPTH);

fwd(ROW*2) right(COL*2)
bracket_mount_pair(SUB_DEVICE_WIDTH, 25.5);

// Shell standalone, side strength over its cap, clamped the same as through bracket()
fwd(ROW*2) right(COL*3)
bracket_shell(SUB_DEVICE_WIDTH, SUB_DEVICE_DEPTH, 25.5,
  BRACKET_DEFAULT_STRENGTH, 200, SUB_OUTER_DEPTH);

// Width landing exactly on the grid, where the wings need no widening at all
fwd(ROW*2) right(COL*4)
bracket_mount_pair(BASE_UNIT*6, 25.5);

// Row 4: boundaries the assertions guard, each at the value that still passes

fwd(ROW*3)
bracket(device_width=BASE_UNIT*6 - TOLERANCE, device_depth=99, device_height=25.5);

fwd(ROW*3) right(COL)
bracket(device_width=90, device_depth=99, device_height=BRACKET_MIN_DEVICE_HEIGHT);

fwd(ROW*3) right(COL*2)
bracket(device_width=90, device_depth=BRACKET_MIN_DEVICE_DEPTH, device_height=25.5);

fwd(ROW*3) right(COL*3)
bracket(device_width=90, device_depth=40.2, device_height=25.5,
  mount_offset_y=40.2 - BRACKET_MIN_DEVICE_DEPTH);

fwd(ROW*3) right(COL*4)
bracket(device_width=90, device_depth=45, device_height=25.5, mount_columns=2);
