// HomeRacker - Rack Panel demo: keystone jack on a split half
//
// Same build-on pattern as keystones_on_full, but on a split Half-Left view. The jack is
// placed in the half's usable band (get_rackpanel_usable_x), demonstrating that a split-aware
// consumer cuts pockets per half. Strong 4mm panel_depth with the back brace. keystone_full()
// self-tags, so it is called BARE; debug_colors renders the jack white for contrast. A single
// jack keeps the render cheap.

include <../lib/rackpanel.scad>
include <../lib/split.scad>
include <../../keystone/lib/keystone.scad>

$fn = 100;

_pw = STD_WIDTH_10INCH;
_units = 1;
_ux = get_rackpanel_usable_x(_pw, HR_RP_SPLIT_HALF, HR_RP_VIEW_HALF_LEFT);

diff("keystone")
rackpanel(panel_width=_pw, panel_height_units=_units, panel_depth=4, brace_enabled=true,
  split_mode=HR_RP_SPLIT_HALF, view_mode=HR_RP_VIEW_HALF_LEFT)
  align(FRONT, inside=true)
    right(_ux)
      keystone_full(panel_depth=get_ks_depth_outer(), debug_colors=true);
