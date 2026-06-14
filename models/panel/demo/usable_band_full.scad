// HomeRacker - Rack Panel demo: usable band (full panel)
//
// Catalog/visual reference for get_rackpanel_usable_width() / get_rackpanel_usable_x().
// A magenta band the exact size of the usable cutout area is attached to the panel BACK
// face, so any overlap with the rackmount mount-surface columns is immediately visible.

include <../lib/rackpanel.scad>
include <../lib/split.scad>

$fn = 100;

_pw = STD_WIDTH_10INCH;
_units = 1;
_h = _units * STD_UNIT_HEIGHT;
_uw = get_rackpanel_usable_width(_pw);
_ux = get_rackpanel_usable_x(_pw);

rackpanel(panel_width=_pw, panel_height_units=_units)
  align(BACK)
    right(_ux)
      color([0.85, 0.1, 0.6])
        cuboid([_uw, 1.5, _h]);
