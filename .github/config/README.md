# GitHub Configuration

## Conventional Commit Types

**IMPORTANT**: Keep commit types in sync between:
- `release-please-config.json` (changelog sections)
- `../workflows/validate-pr-title.yml` (allowed PR title types)

## Release Inputs

`scadfmt` skips commits that touch only `cmd/scadfmt/tests/` (`exclude-paths`), so a canary or test change releases nothing.
