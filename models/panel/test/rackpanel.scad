// HomeRacker - Rack Panel Test
//
// Test file for rackpanel module.

include <../lib/rackpanel.scad>

// === rackpanel_1u standalone ===

// Default: 1U 10" panel, 3 bores
rackpanel_1u();

// 2 bores
right(300) rackpanel_1u(bore_count=2);

// 1 bore
right(600) rackpanel_1u(bore_count=1);

// 0 bores (no holes)
right(900) rackpanel_1u(bore_count=0);

// 19" panel
right(1200) rackpanel_1u(panel_width=STD_WIDTH_19INCH);

// === rackpanel multi-unit — DEFAULT mode ===

// 1U default (2 bores per unit)
up(60) rackpanel(panel_height_units=1);

// 2U default (1 bore per unit)
up(60) right(300) rackpanel(panel_height_units=2);

// 3U default (1 bore per unit)
up(60) right(600) rackpanel(panel_height_units=3);

// 4U default (1 bore per unit)
up(60) right(900) rackpanel(panel_height_units=4);

// === rackpanel multi-unit — FULL mode ===

// 1U full (3 bores per unit)
up(300) rackpanel(panel_height_units=1, bore_mode=RP_BORE_MODE_FULL);

// 2U full
up(300) right(300) rackpanel(panel_height_units=2, bore_mode=RP_BORE_MODE_FULL);

// 3U full
up(300) right(600) rackpanel(panel_height_units=3, bore_mode=RP_BORE_MODE_FULL);

// === rackpanel multi-unit — MINIMAL mode ===

// 1U minimal (1 bore per unit)
up(540) rackpanel(panel_height_units=1, bore_mode=RP_BORE_MODE_MINIMAL);

// 2U minimal (1 bore per unit, both are top+bottom)
up(540) right(300) rackpanel(panel_height_units=2, bore_mode=RP_BORE_MODE_MINIMAL);

// 3U minimal (1 bore top + 1 bore bottom, 0 inner)
up(540) right(600) rackpanel(panel_height_units=3, bore_mode=RP_BORE_MODE_MINIMAL);

// 4U minimal
up(540) right(900) rackpanel(panel_height_units=4, bore_mode=RP_BORE_MODE_MINIMAL);

// === Debug colors ===

up(840) rackpanel(panel_height_units=3, bore_mode=RP_BORE_MODE_DEFAULT, debug_colors=true);

up(840) right(300) rackpanel(panel_height_units=3, bore_mode=RP_BORE_MODE_MINIMAL, debug_colors=true);

// === Panel depth (strong 4mm) ===

// 1U strong panel
up(1080) rackpanel(panel_height_units=1, panel_depth=4);

// 1U standalone strong panel
up(1080) right(300) rackpanel_1u(panel_depth=4);

// 3U strong minimal panel
up(1080) right(600) rackpanel(panel_height_units=3, bore_mode=RP_BORE_MODE_MINIMAL, panel_depth=4);

// === Back-brace stiffener (full panels) ===

// 1U braced (slim spacing)
up(1320) rackpanel(panel_height_units=1, brace_enabled=true);

// 3U braced (slim: 1 band per unit)
up(1320) right(300) rackpanel(panel_height_units=3, brace_enabled=true, brace_rows=3);

// 3U braced (strong: 2 bands per unit)
up(1320) right(600) rackpanel(panel_height_units=3, brace_enabled=true, brace_rows=6);

// 3U braced + minimal bores (lightest stiff combo)
up(1320) right(900) rackpanel(panel_height_units=3, bore_mode=RP_BORE_MODE_MINIMAL, brace_enabled=true);

// 3U braced + strong panel depth (brace shrinks toward knuckle plane)
up(1320) right(1200) rackpanel(panel_height_units=3, panel_depth=4, brace_enabled=true);

// 3U braced debug colors
up(1620) rackpanel(panel_height_units=3, brace_enabled=true, debug_colors=true);

// 19" 2U braced
up(1620) right(300) rackpanel(panel_width=STD_WIDTH_19INCH, panel_height_units=2, brace_enabled=true);
