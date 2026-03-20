include <BOSL2/std.scad>

/* [Base] */
// TODO: enable mount units
// How many units shall the mount span across the support
//mount_units=2; //[2:1:10]
// Shall bores be countersunk or flathead
bore_type="flathead"; //[flathead,countersunk]
// Bore Shaft Diameter in mm
bore_shaft_diameter=4;
// Bore Head Diameter in mm (only relevant if bore_type=countersunk)
bore_head_diameter=8.5;

/* [Finetuning] */
// Defines the angle of the head rejuvenation. 90° is ISO standard. (only relevant if bore_type=countersunk)
countersunk_angle=90;
// Tolerance (in mm) for the bore holes. This is a sane default.
bore_tolerance=0.2;

/* [Hidden] */
// constants which shouldn't be changed

// This is the HomeRacker base unit. don't change this!
BASE_UNIT=15; // mm
// Standard tolerance for the mount. This is a sane default.
TOLERANCE=0.2; // mm
// Base strength. This is a sane default.
BASE_STRENGTH=2; // mm
// Chamfer size. This is a sane default.
CHAMFER=1; // mm
// Lock Pin side length
LOCK_PIN_SIDE=4; // mm
// lock pin edge distance
LOCK_PIN_EDGE_DISTANCE=5.5; // mm
// lock pin chamfer
LOCK_PIN_CHAMFER=0.8; // mm
// Negative chamfer fix:
NEGATIVE_CHAMFER_TRANSLATE=0.01;

mount_units=2;

// Calculate the head depth based on the countersunk angle.
head_depth = bore_head_diameter/2 - bore_shaft_diameter/2 * tan( countersunk_angle/2 );

connector_width_net=BASE_UNIT+TOLERANCE;
connector_width_gross=connector_width_net+BASE_STRENGTH*2;
//Wall Mount
mount_thickness=head_depth+BASE_STRENGTH;
mount_height=mount_units*BASE_UNIT;
mount_width=mount_units*2*BASE_UNIT+connector_width_gross;

bore_shaft_radius=(bore_shaft_diameter+bore_tolerance)/2;
bore_head_radius=(bore_head_diameter+bore_tolerance)/2;
bore_position_x=BASE_STRENGTH+BASE_UNIT/2+TOLERANCE/2+BASE_UNIT;

$fn=100;

echo("head_depth: ", head_depth);
echo("bore_position_x: ", bore_position_x);

// Support Interface
module mount(){
  difference() {
    union(){
      cuboid([mount_width,mount_height,mount_thickness],anchor=CENTER+BOTTOM,chamfer=CHAMFER);
      cuboid([connector_width_gross,mount_height,connector_width_gross],anchor=CENTER+BOTTOM,chamfer=CHAMFER);
    }
    translate([0,0,BASE_STRENGTH])
    cuboid([connector_width_net,mount_height,connector_width_net],anchor=CENTER+BOTTOM);
  }
}

// Lock pin Holes
module lock_pin_hole(){
  // fix for negative chamfer. Otherwise the holes would not reach the surface
  translate([0,0,-NEGATIVE_CHAMFER_TRANSLATE/2])
  cuboid(
    size=[LOCK_PIN_SIDE,LOCK_PIN_SIDE,connector_width_gross+0.01],
    anchor=CENTER+BOTTOM,
    chamfer=-LOCK_PIN_CHAMFER,edges=[TOP,BOTTOM]
    );
}

module lock_pin_holes(){
  // ycopies
  ycopies(BASE_UNIT,mount_units)
  // Create cross
  union(){
    lock_pin_hole();
    yrot(90,cp=[0,0,connector_width_gross/2])
    lock_pin_hole();
  }
}

//// Bores
// Shafts
module bore(){
  if (bore_type=="flathead") {
    cylinder(r=bore_shaft_radius,h=mount_thickness,anchor=CENTER+BOTTOM);
  } else if (bore_type=="countersunk") {
    // Countersunk
    union() {
      // Head
      translate([0,0,mount_thickness])
      cylinder(r1=bore_shaft_radius,r2=bore_head_radius,h=head_depth,anchor=CENTER+TOP);
      // Shaft
      cylinder(r=bore_shaft_radius,h=mount_thickness,anchor=CENTER+BOTTOM);
    }

  }
}

// Assembly
 translate([0,0,BASE_UNIT]) rotate([90,0,0])
union(){
  difference() {
    mount();
    translate([-bore_position_x,0,0])
    bore();
    translate([bore_position_x,0,0])
    bore();

    // Lock Pin Holes
    lock_pin_holes();
  }

}
