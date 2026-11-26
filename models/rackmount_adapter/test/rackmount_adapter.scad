// HomeRacker - Rackmount Adapter Test
//
// Asserts the rack dimensions and that the end covers close the assembly on both adapters,
// then renders the assembly at the smallest, a common and the largest size.

include <../lib/end_cover.scad>

$fn = 16;

// EIA-310 hole spacing: 19" is 18.312", 10" follows the 9.312" convention
function hole_spacing(inches) = inches * 25.4 - 2 * STD_RACK_BORE_EDGE_DISTANCE_X;

assert(abs(hole_spacing(19) - 465.125) < 0.01, "19\" hole spacing follows EIA-310");
assert(abs(hole_spacing(10) - 236.525) < 0.01, "10\" hole spacing follows the industry convention");

// frame width in HomeRacker units
assert(get_hr_units_by_inches(10) == 17, "10\" needs 17 units");
assert(get_hr_units_by_inches(19) == 33, "19\" needs 33 units");
for (inches = [2:20])
  assert(get_adapter_gapfill(inches) >= 0, str(inches, "\": the frame is at least as wide as the rack"));

// the end cover's tongue fills the dock's pocket
assert(get_end_cover_pocket_size(10) == [get_mount_width_total(10), get_connector_cover_depth() - BASE_STRENGTH, get_end_cover_dock_height() - BASE_STRENGTH], "pocket size");

// the frame closes: going around left adapter, bottom cover, right adapter and top cover
// must bring the top cover's left end back onto the left adapter's top dock
module closed_frame(inches, height_units) {
  rackmount_adapter(rackwidth = inches, height_units = height_units) {
    $left = parent();
    attach("end_cover_bottom", "end_cover_left") end_cover(rackwidth = inches, height_units = height_units, type = END_COVER_BOTTOM)
      attach("end_cover_right", "end_cover_bottom") rackmount_adapter(rackwidth = inches, height_units = height_units, side = RIGHT) {
        opening = inches * 25.4 - 2 * STD_MOUNT_SURFACE_WIDTH;
        adapter_width = mount_bridge_width + get_mount_width_total(inches);
        assert(abs(desc_dist($left, CENTER, parent(), CENTER) - (adapter_width + opening)) < 1e-6,
          str(inches, "\" ", height_units, "U: the right adapter mirrors the left one across the rack opening"));
        attach("end_cover_top", "end_cover_right") end_cover(rackwidth = inches, height_units = height_units, type = END_COVER_TOP)
          assert(desc_dist($left, "end_cover_top", parent(), "end_cover_left") < 1e-6,
            str(inches, "\" ", height_units, "U: the top cover closes the frame on the left adapter's top dock"));
      }
  }
}

xdistribute(spacing = 600) {
  closed_frame(2, 1);
  closed_frame(10, 2);
  closed_frame(20, 10);
}
