// HomeRacker - Lock Pin
//
// Fully customizable lock pin part.

// Use the main homeracker library file
include <../main.scad>

/* [Parameters] */

// Type of grip for the lock pin
grip_type = 0; // [0:Standard, 1:Extended, 2:No Grip]

// Neck extension mode
neck_extension = 0; // [0:None, 1:Neck Side, 2:Both Sides, 3:Tail Side]

// Strength of the tension hole (affects how much material is removed for the hole, which in turn affects the flexibility and strength of the lock pin)
strength = 0; // [0:Regular, 1:Slim]

/* [Debug Parameters] */
// Show distinct colors per section for easier debugging
debug_colors = false; // [false,true]
// Enable chamfering on the insertion ends
chamfer_enabled = true; // [false,true]

/* [Hidden] */
$fn = 100;


// --- Examples ---

// Example 1: Create a default lock pin (uses default grip_type)
// lockpin();

// Example 2: Create a lock pin with no grip
// lockpin(grip_type=LP_GRIP_NO_GRIP);

// Example 3: Create a lock pin with neck extension for panel mounting
// lockpin(neck_extension=LP_NECK_EXT_NECK);

// Example 4: Create a lock pin with grip_type and neck_extension as set above

tension_hole_strength_multiplier = strength == 0 ? HR_CORE_LOCKPIN_TENSION_HOLE_STRENGTH_REGULAR :
  strength == 1 ? HR_CORE_LOCKPIN_TENSION_HOLE_STRENGTH_SLIM :
  die(str("Invalid strength value: ", strength));

lockpin(grip_type=grip_type, neck_extension=neck_extension, strength=tension_hole_strength_multiplier, chamfer_enabled=chamfer_enabled, debug_colors=debug_colors);
