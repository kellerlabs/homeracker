include <BOSL2/std.scad>

/* [Hidden] */
TOLERANCE = 0.2;
PRINTING_LAYER_WIDTH = 0.4;
PRINTING_LAYER_HEIGHT = 0.2;
BASE_UNIT = 15;
BASE_STRENGTH = 2;
BASE_CHAMFER = 1;
LOCKPIN_HOLE_CHAMFER = 0.8;
LOCKPIN_HOLE_SIDE_LENGTH = 4;
LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION = [LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH];
LP_GRIP_STANDARD = 0;
LP_GRIP_EXTENDED = 1;
LP_GRIP_NO_GRIP = 2;
LP_NECK_EXT_NONE = 0;
LP_NECK_EXT_GRIP = 1;
LP_NECK_EXT_BOTH = 2;
LP_NECK_EXT_FOOT = 3;
LP_NECK_EXTENSION_UNIT = BASE_STRENGTH + TOLERANCE/2;
HR_YELLOW = "#f7b600";
HR_BLUE = "#0056b3";
HR_RED = "#c41e3a";
HR_GREEN = "#2d7a2e";
HR_CHARCOAL = "#333333";
HR_WHITE = "#f0f0f0";
STD_UNIT_HEIGHT = 44.45;
STD_UNIT_DEPTH = 482.6;
STD_WIDTH_10INCH = 254;
STD_WIDTH_19INCH = 482.6;
STD_MOUNT_SURFACE_WIDTH = 15.875;
STD_RACK_BORE_DISTANCE_Z = 15.875;
STD_RACK_BORE_DISTANCE_MARGIN_Z = 6.35;
tolerance = TOLERANCE;
printing_layer_width = PRINTING_LAYER_WIDTH;
printing_layer_height = PRINTING_LAYER_HEIGHT;
base_unit = BASE_UNIT;
base_strength = BASE_STRENGTH;
base_chamfer = BASE_CHAMFER;
lockpin_hole_chamfer = LOCKPIN_HOLE_CHAMFER;
lockpin_hole_side_length = LOCKPIN_HOLE_SIDE_LENGTH;
lockpin_hole_side_length_dimension = LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION;
$fn = 100;

pusher_length =
    BASE_UNIT + BASE_STRENGTH * 2 + TOLERANCE;
pusher_side =
    LOCKPIN_HOLE_SIDE_LENGTH - TOLERANCE;

grip_width =
    BASE_UNIT/2;
grip_mid_width =
    grip_width - BASE_STRENGTH;
grip_depth =
    BASE_UNIT / 2;

/**
 * 📐 pinpusher module
 *
 * Creates a lockpin pusher tool for the HomeRacker system.
 * Lies flat for optimal printing. Shaft pushes lockpins out of connectors.
 * Prismoid grip for pinching between thumb and index finger.
 */
module pinpusher() {
  color(HR_YELLOW)
  xrot(90)
  prismoid(
    size1 = [grip_width, grip_width],
    size2 = [grip_mid_width, grip_mid_width],
    h = grip_depth,
    shift = [0, -BASE_STRENGTH/2],
    chamfer = BASE_CHAMFER
  )
  attach(TOP, BOTTOM)
  prismoid(
    size1 = [grip_mid_width, grip_mid_width],
    size2 = [grip_width, grip_width],
    shift = [0, BASE_STRENGTH/2],
    h = grip_depth,
    chamfer = BASE_CHAMFER
  )
  align(TOP, FRONT)
  cuboid(
    [pusher_side, pusher_side, pusher_length],
    chamfer = BASE_CHAMFER,
    edges = [LEFT,RIGHT],
    except = [BOTTOM,TOP]
  );
}

pinpusher();
