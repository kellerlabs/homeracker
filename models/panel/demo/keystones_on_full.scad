// HomeRacker - Rack Panel demo: keystone jack on a full panel
//
// Shows the intended way to build on rackpanel: a diff("keystone") pass cuts the keystone
// pocket and leaves the jack body (keystone_full) in the usable band. Uses a strong 4mm
// panel_depth with the back-brace stiffener — the realistic config for a populated panel.
// keystone_full() self-tags its own cutter, so it is called BARE (no outer tag("keystone"),
// which would turn the whole jack into a hole). debug_colors renders the jack white for
// contrast against the yellow panel. A single jack keeps the render cheap.

include <../lib/rackpanel.scad>
include <../lib/split.scad>
include <../../keystone/lib/keystone.scad>

$fn = 100;

_pw = STD_WIDTH_10INCH;
_units = 1;

diff("keystone")
rackpanel(panel_width=_pw, panel_height_units=_units, panel_depth=4, brace_enabled=true)
  align(FRONT, inside=true)
    right(get_rackpanel_usable_x(_pw))
      keystone_full(panel_depth=get_ks_depth_outer(), debug_colors=true);
