include <BOSL2/std.scad>

/* [Hidden] */
// --- from constants.scad ---
TOLERANCE = 0.2;
BASE_UNIT = 15;
BASE_STRENGTH = 2;
BASE_CHAMFER = 1;
LOCKPIN_HOLE_SIDE_LENGTH = 4;
HR_YELLOW = "#f7b600";
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
