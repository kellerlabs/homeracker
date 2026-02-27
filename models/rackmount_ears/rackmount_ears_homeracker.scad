// HomeRacker Rackmount Ears - Lock Pin Variant
//
// Rackmount ears that use homeracker square holes + lock pins
// instead of traditional oval cage-bolt holes. The front face
// features a flange with square lock pin holes for integration
// with the homeracker modular system.
//
// Two flange styles:
//   "support" - 15x15mm beam-shaped flange (slides into connectors)
//   "tab"     - Thin flat tab with square holes (overlaps with support)

include <BOSL2/std.scad>
include <../core/lib/constants.scad>

/* [Hidden] */
$fn=100;
RACK_HEIGHT_UNIT=STD_UNIT_HEIGHT;

/* [Base] */
// Total inner rack width in mm. Set to 0 to auto-detect from rack_size (10" or 19" standard). For custom homeracker racks, set this to your actual rack width.
rack_width=0; // [0:1:600]

// rack size in inches. Only used when rack_width is 0. Only 10 and 19 inch racks are supported.
rack_size=10; // [10:10 inch,19:19 inch]

// Asymetry Slider. CAUTION: there's no sanity check for this slider!
asymetry=0; // [-150:0.1:150]

// shows the distance between the rackmount ears considering the device width.
show_distance=false;

// Width of the device in mm. Will determine the width of the rackmount ears depending on rack width.
device_width=201;
// Height of the device in mm. Will determine the height of the rackmount ear in standard HeightUnits (1HU=44.45 mm). The program will always choose the minimum number of units to fit the device height. Minimum is 1 unit.
device_height=40;

// Thickness of the rackmount ear.
strength=3;

/* [Flange] */
// Flange attachment style
flange_style="support"; // [support:Support beam (15x15mm),tab:Flat tab]
// Flange depth in base units (each unit = 15mm)
flange_depth=1; // [1:1:10]
// Direction the flange extends from the front face
flange_direction="inside"; // [inside:Inside (into rack),outside:Outside (toward device)]

/* [Device Bores] */
// Distance (in mm) of the device's front bores(s) to the front of the device
device_bore_distance_front=9.5;
// Distance (in mm) of the device's bottom bore(s) to the bottom of the device
device_bore_distance_bottom=9.5;
// distance between the bores in the horizontal direction
device_bore_margin_horizontal=25;
// distance between the bores in the vertical direction
device_bore_margin_vertical=25;
// diameter of the bore (should be at least the same as the diameter of the screw shaft)
device_bore_hole_diameter=3.3;
// diameter of the bore head (if not countersunk, just choose the same as device_bore_hole_diameter)
device_bore_hole_head_diameter=6;
// How long is the screw head in depth. This determines the angle of the countersink. The longer the screw head, the more the countersink is inclined.
device_bore_hole_head_length=1.2;
// number of bores in the horizontal direction (will be multiplied by device_bore_rows)
device_bore_columns=2;
// number of bores in the vertical direction (will be multiplied by device_bore_columns)
device_bore_rows=2;
// If true, the device will be aligned to the center of the rackmount ear. Otherwise it will be aligned to the bottom of the rackmount ear.
center_device_bore_alignment=false;

/* [Derived] */
CHAMFER=min(strength/3,0.5);
RACK_HEIGHT_UNIT_COUNT=max(1,ceil(device_height/RACK_HEIGHT_UNIT));
RACK_HEIGHT=RACK_HEIGHT_UNIT_COUNT*RACK_HEIGHT_UNIT;
PIN_HEIGHT_UNITS=max(1,floor(RACK_HEIGHT/BASE_UNIT));
FLANGE_HEIGHT=PIN_HEIGHT_UNITS*BASE_UNIT;
FLANGE_Z_OFFSET=(RACK_HEIGHT-FLANGE_HEIGHT)/2;

RACK_WIDTH_10_INCH_OUTER=STD_WIDTH_10INCH;
RACK_WIDTH_19_INCH=STD_WIDTH_19INCH;

// Debug
echo("Height: ", RACK_HEIGHT);
echo("Pin holes vertical: ", PIN_HEIGHT_UNITS);

function get_bore_depth(device_bore_margin_horizontal,device_bore_columns) =
    (device_bore_columns - 1) * device_bore_margin_horizontal
;
// Calculate the depth of the ear
depth=device_bore_distance_front*2+get_bore_depth(device_bore_margin_horizontal,device_bore_columns);
device_screw_alignment_vertical=
    center_device_bore_alignment ?
        RACK_HEIGHT / 2 :
        device_bore_margin_vertical / 2 + device_bore_distance_bottom
;
device_screw_alignment = [strength,depth/2,device_screw_alignment_vertical];


// lock_pin_hole() - Bidirectional chamfered square hole for lock pins.
// Copied from core/lib/support.scad for include-path compatibility.
module lock_pin_hole() {
    lock_pin_center_side = LOCKPIN_HOLE_SIDE_LENGTH + PRINTING_LAYER_WIDTH*2;
    lock_pin_center_dimension = [lock_pin_center_side, lock_pin_center_side];

    lock_pin_outer_side = LOCKPIN_HOLE_SIDE_LENGTH + LOCKPIN_HOLE_CHAMFER*2;
    lock_pin_outer_dimension = [lock_pin_outer_side, lock_pin_outer_side];

    lock_pin_prismoid_inner_length = BASE_UNIT/2 - LOCKPIN_HOLE_CHAMFER;
    lock_pin_prismoid_outer_length = LOCKPIN_HOLE_CHAMFER;

    module hole_half() {
        union() {
            prismoid(size1=lock_pin_center_dimension, size2=LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION, h=lock_pin_prismoid_inner_length);
            translate([0, 0, lock_pin_prismoid_inner_length]) {
                prismoid(size1=LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION, size2=lock_pin_outer_dimension, h=lock_pin_prismoid_outer_length);
            }
        }
    }

    hole_half();

    mirror([0, 0, 1]) {
        hole_half();
    }
}


module base_ear(width,strength,height) {
    union() {
        // Front face
        cuboid([width,strength,height],anchor=LEFT+BOTTOM+FRONT,chamfer=CHAMFER);
        // Side face
        cuboid([strength,depth,height],anchor=LEFT+BOTTOM+FRONT,chamfer=CHAMFER);
    }
}

module screws_countersunk(length, diameter_head, length_head, diameter_shaft) {
    translate(device_screw_alignment)
    yrot(-90)
    grid_copies(spacing=[device_bore_margin_vertical,device_bore_margin_horizontal],n=[device_bore_rows, device_bore_columns])
    union() {
        cylinder(h=length_head, r1=diameter_head/2, r2=diameter_shaft/2);
        translate([0,0,length_head]) cylinder(h=length-length_head, r=diameter_shaft/2);
    }
}


// Support-beam-shaped flange (15x15mm cross-section).
// Extends from the front face into the rack space.
// Lock pin holes at every BASE_UNIT along Z for horizontal pin insertion.
module flange_support_style(height_units, flange_units) {
    flange_h = height_units * BASE_UNIT;
    flange_d = flange_units * BASE_UNIT;

    difference() {
        cuboid([BASE_UNIT, flange_d, flange_h],
               chamfer=BASE_CHAMFER,
               anchor=RIGHT+BOTTOM+BACK);

        // Lock pin holes through X-axis at every BASE_UNIT along Z
        for (z_idx = [0 : height_units - 1]) {
            translate([-BASE_UNIT/2, -flange_d/2, z_idx * BASE_UNIT + BASE_UNIT/2])
            rotate([0, 90, 0])
            lock_pin_hole();
        }

        // Lock pin holes through Y-axis at every BASE_UNIT along Z
        for (z_idx = [0 : height_units - 1]) {
            for (y_idx = [0 : flange_units - 1]) {
                translate([-BASE_UNIT/2, -(y_idx * BASE_UNIT + BASE_UNIT/2), z_idx * BASE_UNIT + BASE_UNIT/2])
                rotate([90, 0, 0])
                lock_pin_hole();
            }
        }
    }
}


// Thin flat tab flange with square lock pin holes.
// Overlaps alongside a homeracker support; pin goes through both.
module flange_tab_style(height_units, flange_units, ear_strength) {
    flange_h = height_units * BASE_UNIT;
    flange_d = flange_units * BASE_UNIT;

    difference() {
        cuboid([ear_strength, flange_d, flange_h],
               chamfer=CHAMFER,
               anchor=RIGHT+BOTTOM+BACK);

        // Lock pin holes through X-axis at every BASE_UNIT along Z
        // The thin material clips the prismoid to a clean square hole
        for (z_idx = [0 : height_units - 1]) {
            for (y_idx = [0 : flange_units - 1]) {
                translate([-ear_strength/2, -(y_idx * BASE_UNIT + BASE_UNIT/2), z_idx * BASE_UNIT + BASE_UNIT/2])
                rotate([0, 90, 0])
                lock_pin_hole();
            }
        }
    }
}


// Assemble the rackmount ear with homeracker flange
module rackmount_ear_homeracker(asym=0){
    // Determine effective rack width
    effective_rack_width = rack_width > 0 ? rack_width :
        (rack_size == 19 ? RACK_WIDTH_19_INCH : RACK_WIDTH_10_INCH_OUTER);

    // Calculate the width of the ear, enforcing minimum for flange + structural support
    // tab+outside needs at least BASE_UNIT so holes are fully contained in front face
    min_ear_width = (flange_style == "support" || flange_direction == "outside" ? BASE_UNIT : strength) + strength;
    rack_ear_width = max(min_ear_width, (effective_rack_width - device_width) / 2 + asym);

    // Flange thickness for positioning
    flange_thick = flange_style == "support" ? BASE_UNIT : strength;

    // Flange position depends on direction:
    //   "inside"  — on front face, extending into rack (-Y), pins insert from side
    //   "outside" — on outer edge, extending outward (+X), pins insert from front
    flange_x_pos = flange_direction == "inside"
        ? rack_ear_width - flange_thick/2
        : rack_ear_width + flange_depth * BASE_UNIT;
    flange_y_pos = flange_direction == "inside"
        ? 0
        : -flange_thick/2;

    difference() {
        union() {
            // Create the base L-bracket
            base_ear(rack_ear_width, strength, RACK_HEIGHT);

            // Create the flange (tab+outside needs no extra geometry — holes cut into front face)
            if (!(flange_style == "tab" && flange_direction == "outside")) {
                translate([flange_x_pos, flange_y_pos, FLANGE_Z_OFFSET])
                rotate([0, 0, flange_direction == "outside" ? -90 : 0])
                if (flange_style == "support") {
                    flange_support_style(PIN_HEIGHT_UNITS, flange_depth);
                } else {
                    flange_tab_style(PIN_HEIGHT_UNITS, flange_depth, strength);
                }
            }
        }
        // Create the holes for the device screws
        screws_countersunk(length=strength,diameter_head=device_bore_hole_head_diameter,length_head=device_bore_hole_head_length,diameter_shaft=device_bore_hole_diameter);

        // For tab+outside, cut square lock pin holes through the front face
        // Holes centered a half-unit from the outer edge to align with homeracker grid
        if (flange_style == "tab" && flange_direction == "outside") {
            for (z_idx = [0 : PIN_HEIGHT_UNITS - 1]) {
                translate([rack_ear_width - BASE_UNIT/2, strength/2, FLANGE_Z_OFFSET + z_idx * BASE_UNIT + BASE_UNIT/2])
                rotate([90, 0, 0])
                cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, strength + 1],
                       chamfer=-LOCKPIN_HOLE_CHAMFER);
            }
        }
    }
}

// Ear distance
ear_distance = show_distance ? -device_width : -LOCKPIN_HOLE_SIDE_LENGTH;

// Place the ears
rackmount_ear_homeracker(asymetry);

x_mirror_plane = [1,0,0];
translate([ear_distance,0,0])
mirror(x_mirror_plane){
    rackmount_ear_homeracker(-asymetry);
}
