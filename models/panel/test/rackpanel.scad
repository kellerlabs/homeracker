// HomeRacker - Rack Panel Test
//
// Test file for rackpanel module.

include <../lib/rackpanel.scad>
include <../lib/split.scad>

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

// === Usable-frame helper functions ===
// Asserts mirror the helper formulas using the same standard constants (no magic numbers),
// so they verify the math, not a frozen snapshot of today's constant values.

function _approx(a, b, eps=0.001) = abs(a - b) < eps;

// Full: panel_width - 2*mount_surface - tolerance, centred
assert(_approx(get_rackpanel_usable_width(STD_WIDTH_10INCH),
  STD_WIDTH_10INCH - 2 * STD_MOUNT_SURFACE_WIDTH - TOLERANCE), "10\" full usable width");
assert(_approx(get_rackpanel_usable_x(STD_WIDTH_10INCH), 0), "10\" full usable x is centred");

// Half 10": panel_width/2 - knuckle/2 - mount_surface - tolerance/2; the central split-connector
// knuckle stays uncovered, so 2*half + knuckle == full
assert(_approx(get_rackpanel_usable_width(STD_WIDTH_10INCH, HR_RP_SPLIT_HALF, HR_RP_VIEW_HALF_LEFT),
  STD_WIDTH_10INCH / 2 - HR_SPLIT_KNUCKLE_STRENGTH_SLIM / 2 - STD_MOUNT_SURFACE_WIDTH - TOLERANCE / 2),
  "10\" half usable width");
assert(_approx(2 * get_rackpanel_usable_width(STD_WIDTH_10INCH, HR_RP_SPLIT_HALF, HR_RP_VIEW_HALF_LEFT)
  + HR_SPLIT_KNUCKLE_STRENGTH_SLIM, get_rackpanel_usable_width(STD_WIDTH_10INCH)),
  "split halves + knuckle sum to full usable width");

// Half x offset: seam-pinned to the knuckle edge, symmetric, left = +, right = -
assert(_approx(get_rackpanel_usable_x(STD_WIDTH_10INCH, HR_RP_SPLIT_HALF, HR_RP_VIEW_HALF_LEFT),
  STD_MOUNT_SURFACE_WIDTH / 2 + TOLERANCE / 4 - HR_SPLIT_KNUCKLE_STRENGTH_SLIM / 4),
  "10\" half-left usable x toward seam");
assert(_approx(get_rackpanel_usable_x(STD_WIDTH_10INCH, HR_RP_SPLIT_HALF, HR_RP_VIEW_HALF_RIGHT),
  -(STD_MOUNT_SURFACE_WIDTH / 2 + TOLERANCE / 4 - HR_SPLIT_KNUCKLE_STRENGTH_SLIM / 4)),
  "10\" half-right usable x mirrored");

// 19" full + half
assert(_approx(get_rackpanel_usable_width(STD_WIDTH_19INCH),
  STD_WIDTH_19INCH - 2 * STD_MOUNT_SURFACE_WIDTH - TOLERANCE), "19\" full usable width");
assert(_approx(get_rackpanel_usable_width(STD_WIDTH_19INCH, HR_RP_SPLIT_HALF, HR_RP_VIEW_HALF_RIGHT),
  STD_WIDTH_19INCH / 2 - HR_SPLIT_KNUCKLE_STRENGTH_SLIM / 2 - STD_MOUNT_SURFACE_WIDTH - TOLERANCE / 2),
  "19\" half usable width");

// Visual demonstration of the usable band + child passthrough lives in models/panel/demo/
// (committed, one scene per file, rendered to demo/renders/ for the README).
