// HomeRacker - Split Test
//
// Test file for the split feature: split_connector and split_lockpin.

include <../lib/rackpanel.scad>
include <../lib/split.scad>

// === split_connector — both halves ===

// 1U / 2U / 3U complete connector (both knuckle sides)
split_connector(units=1);
right(40) split_connector(units=2);
right(80) split_connector(units=3);

// debug colors
right(120) split_connector(units=2, debug_colors=true);

// === split_connector — single sides (printed with each panel half) ===

up(160) split_connector(units=2, knuckle_side=HR_SPLIT_KNUCKLE_SIDE_LEFT, debug_colors=true);
up(160) right(40) split_connector(units=2, knuckle_side=HR_SPLIT_KNUCKLE_SIDE_RIGHT, debug_colors=true);

// === split_lockpin — standalone ===

up(320) split_lockpin(units=1);
up(320) right(40) split_lockpin(units=2);
up(320) right(80) split_lockpin(units=3);

// debug colors
up(320) right(120) split_lockpin(units=2, debug_colors=true);

// no chamfer
up(320) right(160) split_lockpin(units=2, chamfer_enabled=false);

// === split_lockpin threaded through split_connector ===

up(480) split_connector(units=2, debug_colors=true)
  split_lockpin(units=2, orient=DOWN);

// === assembled split rack panel with lock pin ===

up(640)
rackpanel(panel_width=STD_WIDTH_19INCH, panel_height_units=2,
  split_mode=HR_RP_SPLIT_HALF, view_mode=HR_RP_VIEW_ASSEMBLY, debug_colors=true)
  align(FRONT) split_lockpin(units=2, orient=DOWN);

// === strong (4mm) split rack panel — deeper panel mating with connector ===

up(640) right(300)
rackpanel(panel_width=STD_WIDTH_19INCH, panel_height_units=2,
  split_mode=HR_RP_SPLIT_HALF, view_mode=HR_RP_VIEW_ASSEMBLY, panel_depth=4, debug_colors=true)
  align(FRONT) split_lockpin(units=2, orient=DOWN);

// === braced split rack panel — two flush sub-braces with connector gap ===

// assembly: verify 2 independent braces, centerline gap, bores clear
up(960)
rackpanel(panel_width=STD_WIDTH_19INCH, panel_height_units=2,
  split_mode=HR_RP_SPLIT_HALF, view_mode=HR_RP_VIEW_ASSEMBLY, brace_enabled=true, debug_colors=true)
  align(FRONT) split_lockpin(units=2, orient=DOWN);

// left half only — single bounded sub-brace
up(960) right(300)
rackpanel(panel_width=STD_WIDTH_19INCH, panel_height_units=2,
  split_mode=HR_RP_SPLIT_HALF, view_mode=HR_RP_VIEW_HALF_LEFT, brace_enabled=true, debug_colors=true);

// right half only — single bounded sub-brace
up(960) right(600)
rackpanel(panel_width=STD_WIDTH_19INCH, panel_height_units=2,
  split_mode=HR_RP_SPLIT_HALF, view_mode=HR_RP_VIEW_HALF_RIGHT, brace_enabled=true, debug_colors=true);

// braced + strong depth split assembly (denser bands)
up(960) right(900)
rackpanel(panel_width=STD_WIDTH_19INCH, panel_height_units=2,
  split_mode=HR_RP_SPLIT_HALF, view_mode=HR_RP_VIEW_ASSEMBLY, panel_depth=4,
  brace_enabled=true, brace_rows=4, debug_colors=true)
  align(FRONT) split_lockpin(units=2, orient=DOWN);
