#!/bin/bash
# Run mutmut mutation testing for scadm.
#
# Usage:
#   ./cmd/test/test-mutmut.sh              # full mutation run
#   ./cmd/test/test-mutmut.sh --results    # show results from last run

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.."
readonly REPO_ROOT
readonly SCADM_DIR="${REPO_ROOT}/cmd/scadm"

cd "${SCADM_DIR}"

if [[ "${1:-}" == "--results" ]]; then
  printf "📋 Mutation testing results:\n\n"
  mutmut results
  exit 0
fi

printf "🧬 Running mutation tests (this may take a while)…\n"

mutmut run \
  --paths-to-mutate scadm/ \
  --tests-dir tests/ \
  --runner "python -m pytest tests/ -m 'not integration' -x -q" \
  --no-progress

printf "\n📋 Results:\n\n"
mutmut results
