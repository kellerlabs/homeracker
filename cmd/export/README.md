# Export Tools

## MakerWorld Export

Exports OpenSCAD models for MakerWorld's parametric feature by inlining all local includes into a single file.

## Usage

```bash
python cmd/export/export_makerworld.py <input.scad>
```

Output is written to `models/<model_type>/makerworld/<filename>.scad` where `<model_type>` is auto-detected from the input path (e.g., `core`, `gridfinity`).

## File Structure Assumptions

This script is opinionated about file structure, following **OpenSCAD Customizer** conventions:

**Root files** (files being exported, e.g., `parts/*.scad`):
1. Parameter sections: `/* [SectionName] */` with customizable variables
2. Hidden section: `/* [Hidden] */` with constants/variables hidden from UI
3. Main code: module/function calls that generate geometry

**Variable placement behavior:**
- Variables between `/* [Hidden] */` and first module/function → included in Hidden section (hidden from UI)
- Variables after main code (after last module call) → filtered out (not included in export)
- Best practice: Keep all non-parameter variables in `/* [Hidden] */` section before the first module call

**Library files** (included via `include <...>`):
- Must contain ONLY module/function definitions and constants
- Must NOT have parameter section markers (`/* [Name] */`)
- The script validates this and fails with an error if violated

> [!NOTE]
> Library files (included via `include <...>`) **must not** contain parameter section markers like `/* [Parameters] */` or `/* [Hidden] */`. Only the root file being exported should have these markers. The script will fail with a clear error if it detects parameter sections in library files.

## What it does

- Preserves BOSL2 library references (required by MakerWorld)
- Keeps parameter sections with their comments (for MakerWorld customizer)
- Inlines all local includes recursively
- Strips comments from inlined library code
- Prevents duplicate includes

## Example

```bash
python cmd/export/export_makerworld.py models/core/parts/connector.scad
# → models/core/makerworld/connector.scad

python cmd/export/export_makerworld.py models/gridfinity/parts/baseplate.scad
# → models/gridfinity/makerworld/baseplate.scad
```

## Testing

Use the automated export system:

```bash
# Export all configured models and validate
./cmd/export/export-core-models.sh
```

Or test a single model:

```bash
python cmd/export/export_makerworld.py models/core/parts/connector.scad
# → models/core/makerworld/connector.scad

python cmd/export/export_makerworld.py models/gridfinity/parts/baseplate.scad
# → models/gridfinity/makerworld/baseplate.scad
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

**`export-core-models.sh`** - Orchestrates the export process:
- **Auto-discovers** all `.scad` files from configured paths (`models/core/parts`, `models/gridfinity/parts`)
- Exports each via `export_makerworld.py` (auto-detects model type from path)
- Validates exports with `test-models.sh`

**Pre-commit hook** - Configured in `.pre-commit-config.yaml`:
- Runs `export-core-models.sh` **automatically on every commit**
- Validates exports are in sync with source files
- Only runs when model files in `models/**/*.scad` change
- **You don't need to manually export** - just commit and the hook does it for you

**Model type detection**:
- Input: `models/<model_type>/parts/file.scad` → Output: `models/<model_type>/makerworld/file.scad`
- Works for any model type (core, gridfinity, or future additions)
- Just add your `.scad` files to `<model_type>/parts/` and they'll be auto-exported

**GitHub Actions** - CI workflow runs all pre-commit hooks on PRs

### Running Manually

```bash
# Run all pre-commit hooks
pre-commit run --all-files

# Run only the MakerWorld export validation
pre-commit run validate-makerworld-exports --all-files
```

### Adding New Model Types

To add a new model type (e.g., `models/newtype/`):

1. Create your model files in `models/newtype/parts/*.scad`
2. Edit `cmd/export/export-core-models.sh` and add to `EXPORT_PATHS`:
   ```bash
   EXPORT_PATHS=(
       "models/core/parts"           # Folder: auto-discovers .scad files
       "models/gridfinity/parts"     # Folder: auto-discovers .scad files
       "models/newtype/parts"        # Your new model type
       # "models/newtype/special.scad" # Or: specific file only
   )
   ```
3. Commit - the pre-commit hook will automatically export to `models/newtype/makerworld/`

No other configuration needed - the export script auto-detects model types from paths.

## PNG Export

Exports an isometric preview PNG from any OpenSCAD model.

```bash
./cmd/export/export-png.sh <input.scad> [--camera CAM] [--imgsize WxH] [--colorscheme NAME]
```

Output is written next to the input file as `<basename>.png`.

### Examples

```bash
# Default diagonal view
./cmd/export/export-png.sh models/pinpusher/pinpusher.scad

# Custom camera and size
./cmd/export/export-png.sh models/core/parts/connector.scad --imgsize 1200,900

# Custom camera angle
./cmd/export/export-png.sh models/core/parts/lockpin.scad --camera 0,0,0,45,0,25,100
```
