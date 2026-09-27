#!/bin/bash
# AST check: every .scad file whose change since a base commit is formatting only must give OpenSCAD the same AST.
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

# Headless Linux (CI) needs a virtual display for the OpenSCAD AppImage.
run_openscad() {
  if command -v xvfb-run > /dev/null; then
    xvfb-run -a "${OPENSCAD}" "$@"
  else
    "${OPENSCAD}" "$@"
  fi
}

cd "${REPO_ROOT}"
changed="$(git diff --name-only --diff-filter=M "${BASE}...HEAD" -- '*.scad')"
checked=0
while IFS= read -r file; do
  if [[ -z "${file}" ]]; then
    continue
  fi
  git show "${BASE}:${file}" > "${work}/base.scad"
  # Skip files whose change is more than formatting, and base versions scadfmt cannot read.
  if ! scadfmt format - < "${work}/base.scad" > "${work}/formatted.scad" 2> /dev/null \
    || ! cmp -s "${work}/formatted.scad" "${file}"; then
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

echo "AST check passed: ${checked} formatting-only file(s)"
