#!/bin/bash
# Automated Test Suite - All Models
#
# Discovers and renders all .scad files in:
#   - models/*/test/       — unit tests for model components
#   - models/*/flattened/ — flattened exports for single-file platforms
#
# Render = OpenSCAD compile to binary STL. Validates syntax, geometry,
# and that all includes resolve. A non-zero exit means something is broken.
#
# Uses `scadm render` for the actual rendering.

set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.."

# Discover files
MODELS=()

while IFS= read -r -d '' model; do
  MODELS+=("${model}")
done < <(find models -path "*/test/*.scad" -type f -print0)

# Flattened MakerWorld exports need wrapper files to invoke mw_* modules
TEMP_WRAPPERS=()

cleanup_wrappers() {
  for wrapper in "${TEMP_WRAPPERS[@]:-}"; do
    rm -f "${wrapper}" || true
  done
}

trap cleanup_wrappers EXIT

while IFS= read -r -d '' model; do
  model_dir="$(dirname "${model}")"
  model_base="$(basename "${model}" .scad)"

  wrapper="$(mktemp -p "${model_dir}" ".mwtest.${model_base}.XXXXXX.scad")"
  TEMP_WRAPPERS+=("${wrapper}")

  {
    echo "include <$(basename "${model}")>";
    for mod in mw_assembly_view mw_plate_1 mw_plate_2 mw_plate_3 mw_plate_4; do
      if grep -Eq "^\s*module\s+${mod}\b" "${model}"; then
        echo "${mod}();";
      fi
    done
  } > "${wrapper}"

  MODELS+=("${wrapper}")
done < <(find models -path "*/flattened/*.scad" -type f -not -name ".mwtest.*.scad" -print0)

if [ ${#MODELS[@]} -eq 0 ]; then
  echo "No models found in models/*/test/ or models/*/flattened/"
  exit 1
fi

echo "Found ${#MODELS[@]} model(s) to validate"

scadm render "${MODELS[@]}"
