#!/usr/bin/env bash
# Sync agent instructions from kellerlabs/homeracker
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
API_BASE="https://api.github.com/repos/${REPO}/contents/.claude/rules"

AUTH_ARGS=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    AUTH_ARGS=(-H "Authorization: token ${GITHUB_TOKEN}")
fi

# Explicit files outside .claude/rules/
# AGENTS.md is the canonical instruction set and CLAUDE.md points at it, so the two must travel
# together or the import dangles.
EXPLICIT_FILES=(
    "AGENTS.md"
    "CLAUDE.md"
    ".github/pull_request_template.md"
)

echo "Syncing agent instructions from ${REPO}@${REF}..."

# Discover all path-scoped rule files dynamically
rule_names="$(
    curl -fsSL "${AUTH_ARGS[@]}" --get --data-urlencode "ref=${REF}" "${API_BASE}" \
    | jq -r '
        if type == "array" then
            .[] | select(.type == "file") | .name | select(endswith(".md"))
        else
            error("Expected array from GitHub contents API")
        end
    '
)"

FILES=("${EXPLICIT_FILES[@]}")
while read -r name; do
    [[ -z "${name}" ]] && continue
    FILES+=(".claude/rules/${name}")
done <<< "${rule_names}"

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

# TODO: delete this block once homeracker-exclusive and homeracker-community have each completed
# one sync. A downstream repo that keeps the old directory carries both copies of every guideline,
# and Copilot still applies the stale ones through their applyTo frontmatter.
readonly LEGACY_RULES_DIR=".github/instructions"
if [[ -d "${LEGACY_RULES_DIR}" ]]; then
    rm -rf "${LEGACY_RULES_DIR}"
    echo "  ✓ pruned ${LEGACY_RULES_DIR}"
fi

echo ""
echo "✓ All instructions synced from ${REPO}@${REF}"
