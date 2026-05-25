// HomeRacker - Keystone Sample
//
// Customizable keystone cutout sample for visualization and testing.
// Choose between a single keystone at a specific rotation or a full
// showcase of all rotations side by side.

include <../lib/keystone.scad>

/* [Display Mode] */
// single: one keystone at chosen rotation; full: all rotations side by side
mode = "single"; // [single, full]

/* [Single Mode] */
// Y-axis rotation of the keystone module (degrees)
yrotation = 0; // [0, 90, 180, 270]

/* [Options] */
// Show label plates on the keystone modules
show_labels = true; // [false, true]
// Show distinct colors per section for easier debugging
debug_colors = false; // [false, true]

/* [Hidden] */
$fn = 100;
spacing = 5;

if (mode == "single") {
  keystone_demo_panel(yrot=yrotation, add_label=show_labels, debug_colors=debug_colors);
} else {
  // Full showcase: all 4 rotations attached left to right
  // Labels shown on 90° and 180° variants
  rotations = [0, 90, 180, 270];
  label_rotations = [90, 180];

  widths = [for (r = rotations) get_effective_keystone_width(yrot=r)];

  for (i = [0:len(rotations)-1]) {
    x_offset = (i == 0) ? 0 :
      list_sum([for (j = [0:i-1]) widths[j]]) + spacing * i;

    right(x_offset)
      keystone_demo_panel(
        yrot=rotations[i],
        add_label=in_list(rotations[i], label_rotations),
        debug_colors=debug_colors
      );
  }
}

// Helper: sum a list of numbers (wrapper for older BOSL2 versions)
function list_sum(v) = len(v) == 0 ? 0 : v * [for (i = [0:len(v)-1]) 1];
