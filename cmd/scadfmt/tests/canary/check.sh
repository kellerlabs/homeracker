#!/bin/bash
# Canary check: scadfmt against the pinned OpenSCAD. Needs scadfmt installed and `scadm install` done.
# Override the OpenSCAD binary with OPENSCAD=/path/to/openscad.
set -euo pipefail

CANARY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${CANARY_DIR}/../../../.." && pwd)"
readonly CANARY_DIR REPO_ROOT
readonly OPENSCAD="${OPENSCAD:-${REPO_ROOT}/cmd/linux/openscad-wrapper.sh}"
readonly INPUT="${CANARY_DIR}/canary.scad"
readonly EXPECTED="${CANARY_DIR}/canary.expected.scad"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

# Headless Linux (CI) needs a virtual display for the OpenSCAD AppImage.
run_openscad() {
  if command -v xvfb-run > /dev/null; then
    xvfb-run -a "${OPENSCAD}" "$@"
  else
    "${OPENSCAD}" "$@"
  fi
}

echo "1/4 OpenSCAD parses the canary"
run_openscad -o "${work}/input.ast" "${INPUT}"

echo "2/4 scadfmt output matches canary.expected.scad"
scadfmt format - < "${INPUT}" > "${work}/formatted.scad"
diff -u "${EXPECTED}" "${work}/formatted.scad"

echo "3/4 formatting is idempotent"
scadfmt format --check "${EXPECTED}"

echo "4/4 OpenSCAD sees the same code before and after formatting"
run_openscad -o "${work}/expected.ast" "${EXPECTED}"
# An empty AST on both sides would compare equal without proving anything.
if [[ ! -s "${work}/input.ast" ]]; then
  echo "OpenSCAD wrote an empty AST" >&2
  exit 1
fi
diff -u "${work}/input.ast" "${work}/expected.ast"

echo "Canary passed"
