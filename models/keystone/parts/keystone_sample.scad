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
// Additional tolerance added to the keystone cutout dimensions (mm) to ensure fit, beyond the default TOLERANCE value.
additional_tolerance = 0.0; // [0:0.05:1]
// Depth of the panel the keystone is mounted in (mm)
panel_depth = 9.75; // [9.75:0.25:30]
// Show label plates on the keystone modules
show_labels = true; // [false, true]
// Which side of the jack the label sits on
label_position = "above"; // [above, below]
// Label plate placement: assembly previews the plate in front of its slots; plate lays it
// out print-ready (used when exposing build plates via the Parametric Model Maker).
label_plate_mode = "assembly"; // [assembly, plate]
// Show distinct colors per section for easier debugging
debug_colors = false; // [false, true]

/* [Geometry] */
// Geometry backend: native renders large panels much faster (identical jacks share one
// cached mesh); bosl2 is more readable and supports debug colors but is slow on big panels.
// DISCLAIMER: the native geometry was fully AI-transpiled from the original BOSL2 code.
// It was print-tested with no noticeable difference from the BOSL2 version, but if in doubt,
// use the bosl2 backend (the authored source of truth).
geometry = "native"; // [native, bosl2]

/* [Hidden] */
$fn = 100;
spacing = 5;
// Propagates to all keystone modules like $fn (see ks_use_native() in keystone.scad).
$ks_native = geometry == "native";

if (mode == "single") {
  keystone_demo_panel(additional_tolerance=additional_tolerance, yrot=yrotation, panel_depth=panel_depth, add_label=show_labels, label_plate_mode=label_plate_mode, label_position=label_position, debug_colors=debug_colors);
} else {
  keystone_demo_panel(additional_tolerance=additional_tolerance, yrot=0, panel_depth=panel_depth, add_label=false, label_plate_mode=label_plate_mode, label_position=label_position, debug_colors=debug_colors){
    attach(RIGHT,LEFT) keystone_demo_panel(additional_tolerance=additional_tolerance, yrot=90, panel_depth=panel_depth, add_label=true, label_plate_mode=label_plate_mode, label_position=label_position, debug_colors=debug_colors) {
      attach(RIGHT,LEFT) keystone_demo_panel(additional_tolerance=additional_tolerance, yrot=180, panel_depth=panel_depth, add_label=true, label_plate_mode=label_plate_mode, label_position=label_position, debug_colors=debug_colors) {
        attach(RIGHT,LEFT) keystone_demo_panel(additional_tolerance=additional_tolerance, yrot=270, panel_depth=panel_depth, add_label=false, label_plate_mode=label_plate_mode, label_position=label_position, debug_colors=debug_colors);
      }
    }
  }
}
