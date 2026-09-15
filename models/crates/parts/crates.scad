include <../lib/crates.scad>

/* [General] */
width_inner = 84;
depth_inner = 84;
height_inner = 84;

/* [Advanced] */
bottom_strength = 2;
horizontal_rib_divider = 42;

/* [Debugging] */
debug_colors=false;
chamfer_enabled=true;


/* [Hidden] */

$fn=100;

// Simple example instantiation of a crate
crate(width_inner=width_inner,depth_inner=depth_inner,height_inner=height_inner, bottom_strength=bottom_strength,
  horizontal_rib_divider = horizontal_rib_divider,
  debug_colors=debug_colors,chamfer_enabled=chamfer_enabled
);
