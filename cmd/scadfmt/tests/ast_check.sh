#!/bin/bash
# AST check: every .scad file whose change since a base commit is formatting only must give OpenSCAD the same AST.
# Other changed files (edits to the code, generated flattened/ output) are listed as skipped: their AST may differ.
# Only files modified in place are compared; added and renamed files have no base version at the same path.
# Usage: ast_check.sh <base-commit>. Needs scadfmt installed and `scadm install` done.
# Override the OpenSCAD binary with OPENSCAD=/path/to/openscad.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <base-commit>" >&2
  exit 2
fi
readonly BASE="$1"
REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly REPO_ROOT
readonly OPENSCAD="${OPENSCAD:-${REPO_ROOT}/cmd/linux/openscad-wrapper.sh}"

work="$(mktemp -d)"
base_copy=""
cleanup() {
  rm -rf "${work}"
  if [[ -n "${base_copy}" ]]; then
    rm -f "${base_copy}"
  fi
}
trap cleanup EXIT

# Headless Linux (CI) needs a virtual display for the OpenSCAD AppImage. Its output only shows on failure.
run_openscad() {
  local status=0
  if command -v xvfb-run > /dev/null; then
    xvfb-run -a "${OPENSCAD}" "$@" > "${work}/openscad.log" 2>&1 || status=$?
  else
    "${OPENSCAD}" "$@" > "${work}/openscad.log" 2>&1 || status=$?
  fi
  if [[ "${status}" -ne 0 ]]; then
    cat "${work}/openscad.log" >&2
    return "${status}"
  fi
}

cd "${REPO_ROOT}"
changed="$(git diff --name-only --diff-filter=M "${BASE}...HEAD" -- '*.scad')"
checked=0
skipped=0
while IFS= read -r file; do
  if [[ -z "${file}" ]]; then
    continue
  fi
  git show "${BASE}:${file}" > "${work}/base.scad"
  # Skip files whose change is more than formatting, and base versions scadfmt cannot read.
  if ! scadfmt format - < "${work}/base.scad" > "${work}/formatted.scad" 2> /dev/null \
    || ! cmp -s "${work}/formatted.scad" "${file}"; then
    echo "skipped, not formatting only: ${file}"
    skipped=$((skipped + 1))
    continue
  fi
  # The base version sits next to the file, so its includes resolve the same way.
  base_copy="$(dirname "${file}")/.ast-check-base.scad"
  cp "${work}/base.scad" "${base_copy}"
  run_openscad -o "${work}/before.ast" "${base_copy}"
  rm -f "${base_copy}"
  base_copy=""
  run_openscad -o "${work}/after.ast" "${file}"
  # An empty AST on both sides would compare equal without proving anything.
  if [[ ! -s "${work}/before.ast" ]]; then
    echo "OpenSCAD wrote an empty AST for ${file}" >&2
    exit 1
  fi
  if ! diff -u "${work}/before.ast" "${work}/after.ast"; then
    echo "Formatting changed the AST of ${file}" >&2
    exit 1
  fi
  echo "same AST: ${file}"
  checked=$((checked + 1))
done <<< "${changed}"

echo "AST check passed: ${checked} formatting-only file(s) keep their AST, ${skipped} other changed file(s) skipped"
