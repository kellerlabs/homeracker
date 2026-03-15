#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

# Bootstrap workspace venv if missing
if [[ ! -d .venv ]]; then
  python3 -m venv .venv
fi

# Determine venv paths based on OS
if [[ "${OS:-}" == "Windows_NT" ]]; then
  PIP=".venv/Scripts/pip"
  SCADM=".venv/Scripts/scadm"
else
  PIP=".venv/bin/pip"
  SCADM=".venv/bin/scadm"
fi

# Upgrade scadm from PyPI
"$PIP" install --upgrade --quiet scadm

# Install/update OpenSCAD and libraries
"$SCADM" install
