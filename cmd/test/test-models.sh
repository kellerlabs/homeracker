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

while IFS= read -r -d '' model; do
  MODELS+=("${model}")
done < <(find models -path "*/flattened/*.scad" -type f -print0)

if [ ${#MODELS[@]} -eq 0 ]; then
  echo "No models found in models/*/test/ or models/*/flattened/"
  exit 1
fi

echo "Found ${#MODELS[@]} model(s) to validate"

scadm render "${MODELS[@]}"
