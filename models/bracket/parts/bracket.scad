// HomeRacker - Bracket
// Clamp that wraps a device from above or below and hangs it in a HomeRacker frame via lock pins.

include <../lib/bracket.scad>

/* [Device Measurements] */
// Device width in mm
device_width = 100; // [15:0.1:390]
// Device depth in mm
device_depth = 99; // [15:0.1:400]
// Device height in mm
device_height = 25.5; // [9.4:0.1:250]

/* [Bracket] */
// How far the top plate reaches inward over the device in mm
strength_top = 7.5; // [2:0.1:50]
// How far the side walls reach down the device in mm
strength_sides = 7.5; // [2:0.1:50]
// Which frame supports the wings hook over
mount_axis = "x"; // [x:X (device face), y:Y (frame sides)]
// Whole units added to the span between the wings (odd counts start on the left)
mount_gap_units = 0; // [0:1:20]
// Mount wing columns (0 picks 1 or 2 automatically, based on device depth)
mount_columns = 0; // [0:2]
// Pushes the mount wings back from the front edge in mm (at most device_depth - 15)
mount_offset_y = 0; // [0:0.1:385]

/* [Debug Parameters] */
debug_colors = false; // [false,true]
disable_chamfer = false; // [false,true]

/* [Hidden] */
$fn = 100;

bracket(device_width, device_depth, device_height,
  strength_top=strength_top, strength_sides=strength_sides,
  mount_offset_y=mount_offset_y,
  mount_columns=mount_columns == 0 ? undef : mount_columns,
  mount_axis=mount_axis, mount_gap_units=mount_gap_units,
  debug_colors=debug_colors, disable_chamfer=disable_chamfer);
