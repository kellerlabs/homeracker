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
API_URL="https://api.github.com/repos/${REPO}/contents/.github/instructions?ref=${REF}"

# Explicit files outside .github/instructions/
EXPLICIT_FILES=(
    ".github/copilot-instructions.md"
    ".github/pull_request_template.md"
)

echo "Syncing Copilot instructions from ${REPO}@${REF}..."

# Discover all .instructions.md files dynamically
instruction_names="$(curl -fsSL "${API_URL}" | jq -r '.[].name' | grep '\.instructions\.md$')"

FILES=("${EXPLICIT_FILES[@]}")
while read -r name; do
    FILES+=(".github/instructions/${name}")
done <<< "${instruction_names}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "${TMPDIR}"' EXIT

FAILED=0
for file in "${FILES[@]}"; do
    tmpfile="${TMPDIR}/$(basename "${file}")"

    if curl -fsSL "${BASE_URL}/${file}" -o "${tmpfile}"; then
        dir=$(dirname "${file}")
        mkdir -p "${dir}"
        mv "${tmpfile}" "${file}"
        echo "  ✓ ${file}"
    else
        echo "  ✗ ${file} (download failed)"
        FAILED=1
    fi
done

if [[ "${FAILED}" -eq 1 ]]; then
    echo ""
    echo "ERROR: One or more files failed to download"
    exit 1
fi

echo ""
echo "✓ All instructions synced from ${REPO}@${REF}"
