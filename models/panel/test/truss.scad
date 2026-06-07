// HomeRacker - Truss Grid Test
//
// Test file for the generic truss_grid lattice.

include <../lib/truss.scad>

// === default ===

// default framed + diagonal grid (2 rows, auto columns)
truss_grid(size=[100, 8.8, 100]);

// debug colors
right(140) truss_grid(size=[100, 8.8, 100], debug_colors=true);

// === row-density variants ===

// denser (more bands)
up(140) truss_grid(size=[100, 8.8, 100], rows=4);

// sparser (single band)
up(140) right(140) truss_grid(size=[100, 8.8, 100], rows=1);

// no chamfer (square outer back edge)
up(140) right(280) truss_grid(size=[100, 8.8, 100], chamfer_enabled=false);

// === structural variants ===

// thicker ribs
up(280) truss_grid(size=[100, 8.8, 100], rib=3);

// === aspect-ratio variants ===

// wide + short (panel-like)
fwd(160) truss_grid(size=[220, 8.8, 40], rows=1);

// narrow (split-half-like)
fwd(160) right(260) truss_grid(size=[28, 8.8, 100], rows=3);

// tiny field (one cell — must stay robust)
fwd(160) right(320) truss_grid(size=[18, 8.8, 30], rows=1);
