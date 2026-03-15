#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

# Determine venv paths based on OS
if [[ "${OS:-}" == "Windows_NT" ]]; then
  PIP=".venv/Scripts/pip"
else
  PIP=".venv/bin/pip"
fi

# Upgrade scadm from PyPI
"$PIP" install --upgrade --quiet scadm

# Run scadm install (uses venv's entry point directly)
if [[ "${OS:-}" == "Windows_NT" ]]; then
  .venv/Scripts/scadm install
else
  .venv/bin/scadm install
fi
