/* [SVG Parameters] */
// Amount to "thicken" the SVG shape in mm. This helps to fill small gaps.
thicken_amount = 0.1;  // [0:0.1:5]

// Height of the extrusion in mm
extrusion_height = 20;  // [1:1:100]

/* [Global Settings] */
$fn = 100;

// --- Implementation ---

linear_extrude(height = extrusion_height) {
  offset(delta = thicken_amount) {
    import("spitzzangerl.svg", center = true);
  }
}
