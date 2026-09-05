// Wrapper to export the pieces a panel is built from, for the configurator preview.
// part: "mount_plate" (support_mount_plate for `units`) or "mount_corner".
include <../../../models/panel/lib/panel.scad>

part = "mount_plate";
panel_type = 1;
units = 4;
$fn = 24;

if (part == "mount_plate") support_mount_plate(panel_type=panel_type, units=units, chamfer_enabled=true);
else if (part == "mount_corner") mount_corner(panel_type=panel_type, chamfer_enabled=true);
else panel(units_x=units, units_y=units, panel_type=panel_type);
