#!/bin/bash
# Run pytest with coverage for scadm and enforce a minimum threshold.
#
# The threshold is read from cmd/scadm/.coverage-threshold (an integer
# percentage).  After a successful run the file is updated to the actual
# coverage value so that subsequent runs can only increase, never decrease.
#
# Usage:
#   ./cmd/test/test-coverage.sh          # default: enforce threshold
#   ./cmd/test/test-coverage.sh --report # generate HTML report only (no threshold check)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.."
readonly REPO_ROOT
readonly SCADM_DIR="${REPO_ROOT}/cmd/scadm"
readonly THRESHOLD_FILE="${SCADM_DIR}/.coverage-threshold"
readonly DEFAULT_THRESHOLD=80

report_only=false
if [[ "${1:-}" == "--report" ]]; then
  report_only=true
fi

# Read persisted threshold (fall back to default)
if [[ -f "${THRESHOLD_FILE}" ]]; then
  threshold="$(head -1 "${THRESHOLD_FILE}" | tr -d '[:space:]')"
  # Ensure it is a valid integer
  if ! [[ "${threshold}" =~ ^[0-9]+$ ]]; then
    threshold="${DEFAULT_THRESHOLD}"
  fi
else
  threshold="${DEFAULT_THRESHOLD}"
fi

printf "📊 Running coverage (minimum threshold: %s%%)\n" "${threshold}"

cd "${SCADM_DIR}"

# Run pytest with coverage — capture output and exit code
cov_output="$(python -m pytest tests/ \
  -m "not integration" \
  --cov=scadm \
  --cov-report=term-missing \
  --cov-report=xml:coverage.xml \
  --cov-branch \
  -q 2>&1)" || {
    printf "%s\n" "${cov_output}"
    printf "❌ Tests failed\n"
    exit 1
}

printf "%s\n" "${cov_output}"

# Extract total coverage percentage from the TOTAL line
actual="$(printf "%s" "${cov_output}" | grep -E '^TOTAL' | awk '{print $NF}' | tr -d '%')"

if [[ -z "${actual}" ]]; then
  printf "❌ Could not parse coverage percentage from output\n"
  exit 1
fi

printf "\n📈 Actual coverage: %s%%  |  Threshold: %s%%\n" "${actual}" "${threshold}"

if [[ "${report_only}" == "true" ]]; then
  python -m pytest tests/ \
    -m "not integration" \
    --cov=scadm \
    --cov-report=html \
    --cov-branch \
    -q > /dev/null 2>&1 || true
  printf "📄 HTML report generated in %s/htmlcov/\n" "${SCADM_DIR}"
  exit 0
fi

if (( actual < threshold )); then
  printf "❌ Coverage %s%% is below the required threshold of %s%%\n" "${actual}" "${threshold}"
  exit 1
fi

# Ratchet: persist the actual value so future runs cannot regress
printf "%s\n" "${actual}" > "${THRESHOLD_FILE}"
printf "✅ Coverage meets threshold — updated %s to %s%%\n" "${THRESHOLD_FILE}" "${actual}"
