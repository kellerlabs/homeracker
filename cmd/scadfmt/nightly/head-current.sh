#!/bin/bash
# Fails when the PR branch moved past the run's event, which every re-run replays.
# Usage: REPO, HEAD_REF and HEAD_SHA set, GH_TOKEN with read access. Writes stale=true to $GITHUB_OUTPUT.
set -euo pipefail

remote_sha="$(gh api "repos/${REPO}/git/ref/heads/${HEAD_REF}" --jq .object.sha)"
if [[ "${remote_sha}" != "${HEAD_SHA}" ]]; then
  echo "stale=true" >> "${GITHUB_OUTPUT}"
  echo "::error::${HEAD_REF} moved from ${HEAD_SHA} to ${remote_sha}. Re-run the latest run instead."
  exit 1
fi
