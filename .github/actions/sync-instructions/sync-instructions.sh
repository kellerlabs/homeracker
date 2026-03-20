#!/usr/bin/env bash
# Sync Copilot instructions from kellerlabs/homeracker
#
# Downloads the canonical instruction set and overwrites local copies.
# Designed for downstream repos (e.g., homeracker-exclusive, homeracker-community).
#
# Usage:
#   .github/actions/sync-instructions/sync-instructions.sh          # run locally
#   curl -fsSL <raw-url> | bash                                     # run remotely (see README)

set -euo pipefail

REPO="kellerlabs/homeracker"
REF="${1:-main}"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${REF}"

# Files to sync (source path relative to repo root)
FILES=(
    ".github/copilot-instructions.md"
    ".github/instructions/markdown.instructions.md"
    ".github/instructions/openscad.instructions.md"
    ".github/instructions/python.instructions.md"
    ".github/instructions/renovate.instructions.md"
    ".github/pull_request_template.md"
)

echo "Syncing Copilot instructions from ${REPO}@${REF}..."

FAILED=0
for file in "${FILES[@]}"; do
    dir=$(dirname "${file}")
    mkdir -p "${dir}"

    if curl -fsSL "${BASE_URL}/${file}" -o "${file}"; then
        echo "  ✓ ${file}"
    else
        echo "  ✗ ${file} (download failed)"
        FAILED=1
    fi
done

if [ "${FAILED}" -eq 1 ]; then
    echo ""
    echo "ERROR: One or more files failed to download"
    exit 1
fi

echo ""
echo "✓ All instructions synced from ${REPO}@${REF}"
