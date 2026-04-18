#!/usr/bin/env bash
#
# Local Renovate Configuration Test Script
#
# Tests the renovate.json5 configuration using a remote branch (changes must be committed and pushed before testing).
# Based on: https://github.com/camunda/camunda/blob/main/cmd/renovate/renovate-local.sh
#
# IMPORTANT: Changes must be committed and pushed to a branch BEFORE running this test.
# The script runs Renovate in a Docker container which clones the repository from GitHub.
# Any uncommitted local changes will NOT be visible to Renovate during testing.
#
# Usage:
#   git checkout -b <test-branch>
#   git add <changed-files>
#   git commit -m "test: renovate config changes"
#   git push -u origin <test-branch>
#   ./cmd/test/test-renovate-local.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source common functions
# shellcheck source=../lib/common.sh disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"

# Ensure GitHub CLI is installed
if ! command -v gh >/dev/null 2>&1; then
  log_error "GitHub CLI (gh) is not installed. Please install it first:"
  log_info "https://cli.github.com/"
  exit 1
fi

# Ensure Docker is installed
if ! command -v docker >/dev/null 2>&1; then
  log_error "Docker is not installed. Please install it first:"
  log_info "https://docs.docker.com/get-docker/"
  exit 1
fi

# Login to GitHub CLI if not already authenticated
if ! gh auth status >/dev/null 2>&1; then
  log_info "GitHub CLI not authenticated. Logging in..."
  gh auth login -p https -h github.com -w
fi

# Autodetect Renovate config file
LOCAL_RENOVATE_CONFIG="${WORKSPACE_ROOT}/renovate.json5"
if [ ! -f "$LOCAL_RENOVATE_CONFIG" ]; then
  log_error "Renovate config file not found: $LOCAL_RENOVATE_CONFIG"
  exit 1
fi

# Detect repository name from git remote
REPO_NAME=$(gh repo view --json name,owner -q '.owner.login + "/" + .name' 2>/dev/null)
if [ -z "${REPO_NAME:-}" ]; then
  log_error "Could not detect repository name. Are you in a git repository?"
  exit 1
fi

# Setup directories
GITHUB_TOKEN=$(gh auth token)
LOCAL_CACHE_DIR="${WORKSPACE_ROOT}/renovate_cache"
LOCAL_BASE_DIR="${WORKSPACE_ROOT}/renovate_base"

mkdir -p "${LOCAL_CACHE_DIR}"
mkdir -p "${LOCAL_BASE_DIR}"

# Convert paths to Windows format for Docker on Windows
# Docker Desktop on Windows needs C:\... format in volume mounts
WIN_CONFIG_PATH="$(cygpath -w "${LOCAL_RENOVATE_CONFIG}")"
WIN_CACHE_DIR="$(cygpath -w "${LOCAL_CACHE_DIR}")"
WIN_BASE_DIR="$(cygpath -w "${LOCAL_BASE_DIR}")"

log_info "Repository: ${REPO_NAME}"
log_info "Config: ${LOCAL_RENOVATE_CONFIG}"
log_info "Cache: ${LOCAL_CACHE_DIR}"
log_info ""

start_time=$(date +%s)
log_info "Renovate dry-run started at: $(date)"
log_info "Running in Docker container (this may take a few minutes)..."
log_info ""

# Get current branch name
CURRENT_BRANCH=$(git -C "${WORKSPACE_ROOT}" branch --show-current)
log_info "Testing Renovate config on branch: ${CURRENT_BRANCH}"
log_info ""

# Run renovate in dry-run mode
# Note: MSYS_NO_PATHCONV=1 prevents Git Bash from converting paths
MSYS_NO_PATHCONV=1 docker run --rm \
  -e LOG_LEVEL="debug" \
  -e RENOVATE_DRY_RUN="full" \
  -e RENOVATE_LOG_FORMAT="json" \
  -e RENOVATE_PLATFORM="github" \
  -e RENOVATE_TOKEN="${GITHUB_TOKEN}" \
  -e RENOVATE_REPOSITORIES="${REPO_NAME}" \
  -e RENOVATE_REQUIRE_CONFIG="ignored" \
  -e RENOVATE_BASE_BRANCHES="${CURRENT_BRANCH}" \
  -e RENOVATE_CONFIG_FILE="/usr/src/app/mounted-renovate-config.json" \
  -v "${WIN_CONFIG_PATH}:/usr/src/app/mounted-renovate-config.json:ro" \
  -e RENOVATE_BASE_DIR="/tmp/renovate" \
  -v "${WIN_BASE_DIR}:/tmp/renovate" \
  -e RENOVATE_CACHE_DIR="/cache/renovate" \
  -v "${WIN_CACHE_DIR}:/cache/renovate" \
  renovate/renovate | tee "/tmp/${REPO_NAME//\//_}_$(date +%Y%m%d_%H%M%S).txt"

end_time=$(date +%s)
duration=$((end_time - start_time))
minutes=$((duration / 60))
seconds=$((duration % 60))

log_info ""
log_info "Renovate dry-run finished at: $(date)"
log_success "Total runtime: ${minutes} minutes and ${seconds} seconds"
log_info ""
log_info "Check the output above for detected updates in:"
log_info "  - scadm.json (openscad.version, when pinned)"
