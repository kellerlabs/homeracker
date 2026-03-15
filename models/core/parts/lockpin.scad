// HomeRacker - Lock Pin
//
// Fully customizable lock pin part.

// Use the main homeracker library file
include <../main.scad>

/* [Parameters] */

// Type of grip for the lock pin
grip_type = 0; // [0:Standard, 1:Extended, 2:No Grip]

// Neck extension mode
neck_extension = 0; // [0:None, 1:Grip Side, 2:Both Sides]

/* [Hidden] */
$fn = 100;


// --- Examples ---

// Example 1: Create a default lock pin (uses default grip_type)
// lockpin();

// Example 2: Create a lock pin with no grip
// lockpin(grip_type=LP_GRIP_NO_GRIP);

// Example 3: Create a lock pin with neck extension for panel mounting
// lockpin(neck_extension=LP_NECK_EXT_GRIP);

// Example 4: Create a lock pin with grip_type and neck_extension as set above
color(HR_YELLOW)
lockpin(grip_type=grip_type, neck_extension=neck_extension);
