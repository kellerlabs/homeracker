# 📋 Return the bracket to the open-source catalog and retire flexmount

## 📌 Status

**Accepted**: 2026-09-20

## 🤔 Context

- Flexmount was this repo's open-source universal device mount. It was deprecated once the closed Unimount on MakerWorld took over the job, which left HomeRacker without a device mount anyone could build from source.
- The part that replaced it is the bracket, and it sat in `homeracker-exclusive` as `models/lib/bracket.scad`, reachable only through Unimount.
- A bracket is a single printable part, usable on its own or as one half of a larger mount. It belongs in the catalog next to the other building blocks.

## 🔧 Decision

- Move the bracket into `homeracker` as `models/bracket/`, MIT-licensed, following the standard lib/parts/test/README layout. This restores in support what flexmount used to provide.
- Delete `models/flexmount/`. The bracket supersedes it, and keeping a deprecated model beside its replacement only splits attention. Its history stays in git, and the MakerWorld listing its README pointed at is unaffected.
- The public entrypoint is `bracket()`, the full printable part. `bracket_shell()`, `bracket_mount()` and `bracket_mount_pair()` expose the halves.
- The rackmount flush distance becomes a plain `mount_offset_y` and the `MOUNT_VAR_*` flag disappears, because the offset is a distance, not a variant. `homeracker-exclusive` computes it and passes it in. MakerWorld `VIEW_*` plate modes stay there too.
- Mount column count derives from geometry (two columns once the grid spacing clears one wing footprint) rather than from the rackmount threshold constants it used before.
- Rejected: keeping a thin shim in `homeracker-exclusive`. Two files describing one part invites drift, and the glue it would hold is three lines.
- Rejected: leaving flexmount in place as deprecated. It has had no maintenance path since its successor went closed, and now that the successor is open there is nothing left for it to document.

## 📊 Consequences

- HomeRacker has a device mount in source again, buildable without a MakerWorld licence.
- Unimount keeps its geometry byte for byte, verified by STL volume and bounding box across 94 parameter permutations against the closed original.
- `homeracker-exclusive` now depends on a released `homeracker` version that contains the bracket, so its `scadm.json` pin has to move before its flattened exports rebuild.
- In automatic mode the second mount column now appears from 45mm of device depth rather than 49mm, because the threshold follows the wing footprint instead of a reused rackmount constant. `homeracker-exclusive` pins the count explicitly, so Unimount is unaffected.
- A device whose width lands exactly on the 15mm grid once reserved a whole extra rack unit, because the wing widening was computed without wrapping at zero. The wings now take their width from the support span rounded up to the grid. This narrows the part by one unit at widths of `15n - 0.2mm`, Unimount included, and leaves every other width as it was.
- Five inputs that used to render broken, empty or pointless geometry now fail an assertion naming the value that works: minimum device height, minimum device depth, maximum mount offset, a forced second column that would not fit, and a shell strength below one wall thickness.
- The attachable bounding box covers the shell only, not the mount wings. Callers placing parts near the wings position them by hand.
- Anyone following an old link to `models/flexmount/` lands on a 404 until they find the bracket.
