#!/usr/bin/env bash
# Export all HomeRacker models for MakerWorld
#
# Processes configured models/folders, exports each via export_makerworld.py,
# then validates exports with test-models.sh.
#
# Exit codes:
#   0 - All exports succeeded and validated
#   1 - Export or validation failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Configurable array of paths to export
# Can contain:
#   - Directories: auto-discover all .scad files
#   - Files: export specific .scad file
EXPORT_PATHS=(
    "models/core/parts"
    "models/gridfinity/parts"
    "models/pinpusher/parts"
    "models/rackmount_ears/parts"
    "models/wallmount/parts"
)

echo "Exporting HomeRacker models for MakerWorld..."

# Collect all files to export
FILES_TO_EXPORT=()

for path in "${EXPORT_PATHS[@]}"; do
    full_path="${PROJECT_ROOT}/${path}"

    if [ -d "$full_path" ]; then
        # Directory: auto-discover .scad files
        while IFS= read -r -d '' scad_file; do
            FILES_TO_EXPORT+=("$scad_file")
        done < <(find "$full_path" -maxdepth 1 -name "*.scad" -type f -print0)
    elif [ -f "$full_path" ]; then
        # Specific file
        FILES_TO_EXPORT+=("$full_path")
    else
        echo "ERROR: Path not found: $path"
        exit 1
    fi
done

if [ ${#FILES_TO_EXPORT[@]} -eq 0 ]; then
    echo "ERROR: No files found to export"
    exit 1
fi

echo "Found ${#FILES_TO_EXPORT[@]} model(s) to export"

# Export each file
FAILED=0
for file in "${FILES_TO_EXPORT[@]}"; do
    echo "Exporting: $file"
    if ! python "${SCRIPT_DIR}/export_makerworld.py" "$file"; then
        echo "ERROR: Export failed for $file"
        FAILED=1
    fi
done

if [ $FAILED -eq 1 ]; then
    echo "ERROR: One or more exports failed"
    exit 1
fi

# Validate exports
echo ""
echo "Validating exported models..."
if ! "${PROJECT_ROOT}/cmd/test/test-models.sh"; then
    echo ""
    echo "ERROR: Validation failed"
    echo ""
    echo "To run tests manually:"
    echo "  ./cmd/test/test-models.sh"
    exit 1
fi

echo ""
echo "✓ All exports completed and validated successfully"
