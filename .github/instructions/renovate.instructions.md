---
applyTo: "renovate.json5,renovate-dependencies.json"
---

# Renovate Guidelines

## Version Pinning

- **MANDATORY** for all dependencies — Renovate manages updates.
- Pin exact versions, never use version ranges or `latest`.
- Research Renovate docs first when introducing new pinning patterns to ensure proper tracking.
- Examples: Docker tags, Python packages, GitHub Actions, OpenSCAD versions.

## Configuration

- Main config: `renovate.json5` in project root.
- Shared dependency preset: `renovate-dependencies.json` (consumed by downstream repos).
- Custom datasources and managers: defined in `renovate.json5` when upstream packages lack standard tracking.

## Testing

- Run `cmd/test/test-renovate-local.sh` to verify config changes locally.
- **Important**: Changes MUST be pushed to the current branch before running the test — the script runs in a Docker context and pulls from remote.
