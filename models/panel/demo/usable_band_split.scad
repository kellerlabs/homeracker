// HomeRacker - Rack Panel demo: usable band (split panel, assembled)
//
// Catalog/visual reference for the split-half variants of get_rackpanel_usable_width() /
// get_rackpanel_usable_x(). Each half carries its own magenta band on the BACK face; the
// two bands leave the central split-connector knuckle uncovered, confirming that
// 2*half + knuckle == full and that each band stays clear of its outer mount column.

include <../lib/rackpanel.scad>
include <../lib/split.scad>

$fn = 100;

_pw = STD_WIDTH_10INCH;
_units = 1;
_h = _units * STD_UNIT_HEIGHT;
_uw = get_rackpanel_usable_width(_pw, HR_RP_SPLIT_HALF, HR_RP_VIEW_HALF_LEFT);
_ux_l = get_rackpanel_usable_x(_pw, HR_RP_SPLIT_HALF, HR_RP_VIEW_HALF_LEFT);
_ux_r = get_rackpanel_usable_x(_pw, HR_RP_SPLIT_HALF, HR_RP_VIEW_HALF_RIGHT);

module band_marker(width) color([0.85, 0.1, 0.6]) cuboid([width, 1.5, _h]);

rackpanel(panel_width=_pw, panel_height_units=_units,
  split_mode=HR_RP_SPLIT_HALF, view_mode=HR_RP_VIEW_HALF_LEFT) {
  align(BACK) right(_ux_l) band_marker(_uw);
  attach(RIGHT, LEFT)
    rackpanel(panel_width=_pw, panel_height_units=_units,
      split_mode=HR_RP_SPLIT_HALF, view_mode=HR_RP_VIEW_HALF_RIGHT)
      align(BACK) right(_ux_r) band_marker(_uw);
}
