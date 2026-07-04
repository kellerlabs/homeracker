include <BOSL2/std.scad>

/* [General] */

// tolerance to account for print inaccuracy
clearance = 0.2;

// print only a small demo to test fit
print_demo = false;

/* [Hidden] */
// --- from constants.scad ---
HR_EPSILON = 0.01;
HR_YELLOW = "#f7b600";
HR_BLUE = "#0056b3";
HR_RED = "#c41e3a";
HR_CHARCOAL = "#333333";
// --- from adapter.scad ---
_strength = 2.5;
ADAPTER_PLATE_WIDTH = 125;
ADAPTER_PLATE_HEIGHT = 91;
ADAPTER_PLATE_THICKNESS = 2.5;
ADAPTER_PLATE_RADIUS = 10;
ADAPTER_PLATE_HOOK_WIDTH = 60.8;
ADAPTER_PLATE_HOOK_HEIGHT = 2.5;
ADAPTER_PLATE_HOOK_DEPTH = 2.5;
ADAPTER_BORE_HOLE_DISTANCE_EDGE = 3.8;
ADAPTER_BORE_HOLE_DIAMETER = 6.3;
CAMERA_HEIGHT = 30.2;
CAMERA_WIDTH = 61.5;
CAMERA_DEPTH = 18;
CAMERA_ROUNDING = 10;
CAMERA_OVERLAP = 1;
CAMERA_LENS_HORIZONTAL_OFFSET = 15;
CAMERA_ENCLOSURE_ANGLE = 50;
$fn=100;
module elgato_prompter_insta360_link_2c_pro_adapter(clearance=0.2, print_demo=false) {
  intersection() {
    diff()
    color_this(HR_YELLOW)
    cuboid([ADAPTER_PLATE_WIDTH - clearance, ADAPTER_PLATE_HEIGHT - clearance, ADAPTER_PLATE_THICKNESS], rounding=ADAPTER_PLATE_RADIUS, except=[TOP, BOTTOM]) {

      align(TOP, FRONT, inset=-ADAPTER_PLATE_HOOK_DEPTH)
        color_this(HR_CHARCOAL)
        cuboid([ADAPTER_PLATE_HOOK_WIDTH, ADAPTER_PLATE_HOOK_DEPTH * 2, ADAPTER_PLATE_HOOK_HEIGHT]);

      align(BACK, LEFT, inside=true)
        right(ADAPTER_BORE_HOLE_DISTANCE_EDGE)
        fwd(ADAPTER_BORE_HOLE_DISTANCE_EDGE)
        tag("remove")
        color_this(HR_RED)
        cylinder(h=ADAPTER_PLATE_THICKNESS + HR_EPSILON, r=ADAPTER_BORE_HOLE_DIAMETER / 2);

      align(BACK, RIGHT, inside=true)
        left(ADAPTER_BORE_HOLE_DISTANCE_EDGE)
        fwd(ADAPTER_BORE_HOLE_DISTANCE_EDGE)
        tag("remove")
        color_this(HR_RED)
        cylinder(h=ADAPTER_PLATE_THICKNESS + HR_EPSILON, r=ADAPTER_BORE_HOLE_DIAMETER / 2);

      align(CENTER, BOTTOM, inside=true)
        right(CAMERA_LENS_HORIZONTAL_OFFSET)
        tag("enclosure")
        prismoid(size2=[CAMERA_WIDTH + _strength, CAMERA_HEIGHT + _strength], xang=CAMERA_ENCLOSURE_ANGLE, yang=CAMERA_ENCLOSURE_ANGLE, rounding=CAMERA_ROUNDING + _strength/2, h=CAMERA_DEPTH);

      align(CENTER, BOTTOM, inside=true, overlap=CAMERA_OVERLAP)
        right(CAMERA_LENS_HORIZONTAL_OFFSET)
        color_this(HR_BLUE)
        tag("remove")
        cuboid([CAMERA_WIDTH + clearance / 2, CAMERA_HEIGHT + clearance / 2, CAMERA_DEPTH + HR_EPSILON], rounding=CAMERA_ROUNDING, except=[TOP, BOTTOM]);

      align(CENTER, BOTTOM, inside=true, inset=-HR_EPSILON / 2)
        right(CAMERA_LENS_HORIZONTAL_OFFSET)
        color_this(HR_BLUE)
        tag("remove")
        cuboid([CAMERA_WIDTH - CAMERA_OVERLAP, CAMERA_HEIGHT - CAMERA_OVERLAP, CAMERA_DEPTH + HR_EPSILON], rounding=CAMERA_ROUNDING - CAMERA_OVERLAP / 2, except=[TOP, BOTTOM]);
    }

    if (print_demo) {
      right(CAMERA_LENS_HORIZONTAL_OFFSET)
        cuboid([CAMERA_WIDTH + 10, CAMERA_HEIGHT + 10, CAMERA_DEPTH + 50]);
    }
  }
}

module mw_assembly_view() {
  color(HR_YELLOW)
  elgato_prompter_insta360_link_2c_pro_adapter(clearance=clearance, print_demo=print_demo);
}

module mw_plate_1() {
  color(HR_YELLOW)
  elgato_prompter_insta360_link_2c_pro_adapter(clearance=clearance, print_demo=print_demo);
}
