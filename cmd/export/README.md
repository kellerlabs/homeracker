# Export Tools

## MakerWorld Export

Exports OpenSCAD models for MakerWorld's parametric feature by inlining all local includes into a single file.

## Usage

```bash
# Preferred: use scadm (see cmd/scadm/README.md for full docs)
scadm flatten models/core/parts/connector.scad -o models/core/flattened/connector.scad
scadm flatten --all  # batch-flatten from scadm.json config

# Legacy: standalone script (still works but scadm is preferred)
python cmd/export/export_makerworld.py <input.scad>
```

Output is written to `models/<model_type>/flattened/<filename>.scad` where `<model_type>` is auto-detected from the input path (e.g., `core`, `gridfinity`).

## File Structure Assumptions

This script follows **OpenSCAD Customizer** conventions:

**Root files** (files being exported, e.g., `parts/*.scad`):
1. Parameter sections: `/* [SectionName] */` with customizable variables
2. Hidden section: `/* [Hidden] */` with constants/variables hidden from UI
3. Main code: module/function calls that generate geometry

**Variable placement behavior:**
- Variables inside `/* [SectionName] */` blocks → preserved in their respective sections
- Variables in `/* [Hidden] */` section → included in the Hidden section
- Variables can be defined anywhere in any file

**Library files** (included via `include <...>`):
- May contain module/function definitions, constants, and variables in any order
- Section markers in library files are silently ignored — only root file sections matter
- Only **effectively used** definitions are included — unused code is omitted
- Library variables appear in the Hidden section with an origin comment

> [!NOTE]
> Section markers (`/* [Name] */`) in library files are silently ignored. Only the root file's sections are preserved in the output. Unused modules, functions, and variables from the dependency chain are automatically omitted.

## What it does

- Preserves BOSL2 library references (required by MakerWorld)
- Keeps parameter sections with their comments (for MakerWorld customizer)
- Inlines only effectively used definitions from local includes
- Strips comments from inlined library code
- Prevents duplicate includes
- Adds origin comments for library variables

## Example

```bash
python cmd/export/export_makerworld.py models/core/parts/connector.scad
# → models/core/flattened/connector.scad

python cmd/export/export_makerworld.py models/gridfinity/parts/baseplate.scad
# → models/gridfinity/flattened/baseplate.scad
```

## Testing

```bash
# Flatten and validate all configured models
scadm flatten --all

# Discover and render all models (test/ + flattened/ dirs)
./cmd/test/test-models.sh

# Render a single flattened export
scadm render models/core/flattened/connector.scad
```

## Automated Export System

### Setup Pre-commit Hooks

This project uses the [pre-commit](https://pre-commit.com/) framework:

```bash
# Install pre-commit (if not already installed)
pip install pre-commit

# Install git hooks
pre-commit install
```

### Components

**`scadm flatten --all`** - Orchestrates the flatten process:
- Reads `"flatten"` entries from `scadm.json` for src/dest path mappings
- Flattens each `.scad` file by inlining all local includes
- Skips unchanged files via SHA256 checksums (`models/.flatten-checksums`, gitignored; cached in CI)

**Pre-commit hook** - Configured in `.pre-commit-config.yaml`:
- Runs `scadm flatten --all` **automatically on every commit**
- Validates flattened files are in sync with source files
- Only runs when model files in `models/**/*.scad` or `cmd/scadm/scadm/flatten.py` change
- **You don't need to manually flatten** - just commit and the hook does it for you

**GitHub Actions** - CI workflow runs all pre-commit hooks on PRs

### Running Manually

```bash
# Run all pre-commit hooks
pre-commit run --all-files

# Run only the flatten validation
pre-commit run validate-flatten-exports --all-files
```

### Adding New Model Types

To add a new model type (e.g., `models/newtype/`):

1. Create your model files in `models/newtype/parts/*.scad`
2. Add a flatten entry to `scadm.json`:
   ```json
   {
     "flatten": [
       {"src": "models/core/parts", "dest": "models/core/flattened"},
       {"src": "models/newtype/parts", "dest": "models/newtype/flattened"}
     ]
   }
   ```
3. Commit — the pre-commit hook will automatically flatten to `models/newtype/flattened/`

## 📐 Image Dimensions

Prints pixel dimensions of image files (WebP, PNG, JPEG) by reading file headers directly — no external dependencies.

```bash
# Directory of images
python cmd/export/image_dimensions.py path/to/images/

# Single file
python cmd/export/image_dimensions.py path/to/image.webp
```

Output: `filename.webp: 4032x2268`

## PNG Export

Exports an isometric preview PNG from any OpenSCAD model.

```bash
./cmd/export/export-png.sh <input.scad> [--camera CAM] [--imgsize WxH] [--colorscheme NAME]
```

Output is written to a `renders/` subfolder next to the input file as `renders/<basename>.png`.

### Examples

```bash
# Default diagonal view
./cmd/export/export-png.sh models/pinpusher/pinpusher.scad

# Custom camera and size
./cmd/export/export-png.sh models/core/parts/connector.scad --imgsize 1200,900

# Custom camera angle
./cmd/export/export-png.sh models/core/parts/lockpin.scad --camera 0,0,0,45,0,25,100
```
