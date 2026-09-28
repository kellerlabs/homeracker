#!/bin/bash
# Patch guard: fails when the staged changes touch more than the scadfmt agent may change.
# Allowed: formatter sources, the two canary files and new test files. Existing tests, check scripts and the
# coverage config stay untouched, so the checks that judge the patch are the ones a person already reviewed.
# Usage: stage the patch (git apply --index), then run a copy of this script taken before applying it.
set -euo pipefail

changes="$(git diff --cached --name-status --no-renames)"
if [[ -z "${changes}" ]]; then
  echo "::error::The patch changes nothing."
  exit 1
fi

rejected=""
while IFS=$'\t' read -r status path; do
  case "${status}:${path}" in
    [AM]:cmd/scadfmt/scadfmt/*.py) ;;
    M:cmd/scadfmt/tests/canary/canary.scad) ;;
    M:cmd/scadfmt/tests/canary/canary.expected.scad) ;;
    A:cmd/scadfmt/tests/test_*.py) ;;
    *) rejected+="${status} ${path}"$'\n' ;;
  esac
done <<< "${changes}"

if [[ -n "${rejected}" ]]; then
  echo "::error::The patch changes files the scadfmt agent may not change:"
  printf '%s' "${rejected}"
  exit 1
fi
echo "Patch stays within what the scadfmt agent may change."
