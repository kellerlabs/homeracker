#!/bin/bash
# E2E probe: breaks scadfmt for Unicode identifiers, which OpenSCAD added after the probe's old nightly
# (PROBE_OLD_NIGHTLY in scadfmt-agent.yml), so the agent has to find the upstream change and fix scadfmt again.
# Commits the break, so the agent's patch, the guard and the tests all build on it. Fails once the line moved.
set -euo pipefail

readonly FILE="cmd/scadfmt/scadfmt/tokenizer.py"

python3 - "${FILE}" <<'EOF'
import sys

path = sys.argv[1]
old = '(Kind.IDENT, re.compile(r"\\$\\w*|[^\\W\\d]\\w*")),'
new = '(Kind.IDENT, re.compile(r"\\$\\w*|[^\\W\\d]\\w*", re.ASCII)),'
with open(path, encoding="utf-8") as f:
    source = f.read()
if source.count(old) != 1:
    sys.exit(f"::error::{path} no longer has the identifier pattern the probe breaks. Update probe-break.sh.")
with open(path, "w", encoding="utf-8") as f:
    f.write(source.replace(old, new))
EOF

git -c core.hooksPath=/dev/null -c user.name="scadfmt-e2e" -c user.email="scadfmt-e2e@users.noreply.github.com" \
  commit --quiet --no-verify -m "test(scadfmt): break Unicode identifiers for the e2e probe" -- "${FILE}"
echo "Broke Unicode identifiers in ${FILE}."
