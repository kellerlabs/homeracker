#!/usr/bin/env bash
# Export all HomeRacker models for MakerWorld
#
# Processes configured models/folders, exports each via export_makerworld.py.
# Uses per-model checksums to skip unchanged models and only validates
# models whose exports actually changed.
#
# Exit codes:
#   0 - All exports succeeded and validated
#   1 - Export or validation failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

CHECKSUMS_FILE="${PROJECT_ROOT}/models/.makerworld-checksums"
EXPORT_SCRIPT="${SCRIPT_DIR}/export_makerworld.py"

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

# Compute checksum from transitive local include dependencies via Python.
# Uses the same include-resolution logic as export_makerworld.py.
compute_model_checksum() {
    local part_file="$1"
    python "$EXPORT_SCRIPT" --checksum "$part_file"
}

# Get stored checksum for a model from checksums file
get_stored_checksum() {
    local rel_path="$1"
    if [ -f "$CHECKSUMS_FILE" ]; then
        awk -v rel_path="$rel_path" '$2 == rel_path { print $1 }' "$CHECKSUMS_FILE" || true
    fi
}

# Determine makerworld output path for a part file
get_makerworld_path() {
    local part_file="$1"
    local model_type
    model_type=$(echo "$part_file" | sed "s|${PROJECT_ROOT}/models/||" | cut -d'/' -f1)
    echo "models/${model_type}/makerworld/$(basename "$part_file")"
}

echo "Exporting HomeRacker models for MakerWorld..."

# Collect all files to export
FILES_TO_EXPORT=()

for path in "${EXPORT_PATHS[@]}"; do
    full_path="${PROJECT_ROOT}/${path}"

    if [ -d "$full_path" ]; then
        while IFS= read -r -d '' scad_file; do
            FILES_TO_EXPORT+=("$scad_file")
        done < <(find "$full_path" -maxdepth 1 -name "*.scad" -type f -print0)
    elif [ -f "$full_path" ]; then
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

# Export each file, skipping unchanged models
FAILED=0
SKIPPED=0
EXPORTED=0
CHANGED_MAKERWORLD_FILES=()
NEW_CHECKSUMS=()

for file in "${FILES_TO_EXPORT[@]}"; do
    rel_path="${file#"${PROJECT_ROOT}/"}"
    current_checksum=$(compute_model_checksum "$file")
    stored_checksum=$(get_stored_checksum "$rel_path")

    if [ "$current_checksum" = "$stored_checksum" ]; then
        echo "Skipping (unchanged): $rel_path"
        SKIPPED=$((SKIPPED + 1))
        NEW_CHECKSUMS+=("${current_checksum}  ${rel_path}")
        continue
    fi

    echo "Exporting: $rel_path"
    if ! python "$EXPORT_SCRIPT" "$file"; then
        echo "ERROR: Export failed for $rel_path"
        FAILED=1
        continue
    fi
    EXPORTED=$((EXPORTED + 1))

    # Check if the makerworld output actually changed
    mw_path=$(get_makerworld_path "$file")
    if git diff --quiet -- "$mw_path" 2>/dev/null && \
       ! git ls-files --others --exclude-standard -- "$mw_path" 2>/dev/null | grep -q .; then
        echo "  Output unchanged: $mw_path"
    else
        echo "  Output changed: $mw_path"
        CHANGED_MAKERWORLD_FILES+=("${PROJECT_ROOT}/${mw_path}")
    fi

    NEW_CHECKSUMS+=("${current_checksum}  ${rel_path}")
done

if [ $FAILED -eq 1 ]; then
    echo "ERROR: One or more exports failed"
    exit 1
fi

# Update checksums file
printf '%s\n' "${NEW_CHECKSUMS[@]}" | sort -k2 > "$CHECKSUMS_FILE"

echo ""
echo "Summary: ${SKIPPED} skipped, ${EXPORTED} exported, ${#CHANGED_MAKERWORLD_FILES[@]} changed"

# Validate only changed exports
if [ ${#CHANGED_MAKERWORLD_FILES[@]} -gt 0 ]; then
    echo ""
    echo "Validating changed exports..."
    if ! "${PROJECT_ROOT}/cmd/test/openscad-render.sh" "${CHANGED_MAKERWORLD_FILES[@]}"; then
        echo ""
        echo "ERROR: Validation failed"
        exit 1
    fi
else
    echo "No exports changed, skipping validation"
fi

echo ""
echo "✓ All exports completed successfully"
