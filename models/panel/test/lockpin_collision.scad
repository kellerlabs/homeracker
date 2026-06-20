// HomeRacker - Panel lockpin name-collision regression test
//
// Guards the panel_lockpin_hole rename. panel.scad's shallow mount-hole module used to be
// named lockpin_hole, colliding with the reusable core lockpin_hole(depth=...) (core/lib/
// lockpin.scad). When both ended up in scope together — e.g. a model that includes panel.scad
// alongside split.scad (which includes core lockpin) — the core module shadowed the panel one,
// so panel mount holes rendered with depth=undef and tripped is_vector(size,3).
//
// Here we deliberately put BOTH modules in scope (panel.scad first, then core lockpin last so
// the core definition wins any collision) and render panels whose mounts exercise the panel-side
// holes. Pre-rename this aborts; post-rename it renders cleanly.

include <../lib/panel.scad>
include <../../core/lib/lockpin.scad>

// Full-cover panel: corner connector mounts subtract panel_lockpin_hole.
panel(4, 4, HR_PANEL_TYPE_FULLCOVER);

// Inter-fit panel with open edges: edge walls subtract panel_lockpin_hole rows.
right(120)
panel(4, 4, HR_PANEL_TYPE_INTERFIT,
  mount_north=false, mount_south=false, mount_east=false, mount_west=false);
