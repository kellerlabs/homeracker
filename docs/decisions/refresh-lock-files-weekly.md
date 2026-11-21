# 📋 Refresh lock files weekly to fix transitive vulnerabilities

## 📌 Status

**Accepted**: 2026-11-21

## 🤔 Context

- Every open Dependabot alert sat in a transitive npm dependency (`undici`, `fast-uri`, `minimatch`). Renovate bumps direct dependencies only, so these versions stayed pinned in the lock files.
- A from-scratch lock file resolved 25 of 26 alerts; the last one needs a direct `typescript-eslint` bump, which Renovate already proposes.

## 🔧 Decision

- [`renovate.json5`](../../renovate.json5) enables `lockFileMaintenance` on Saturdays before 04:00 UTC, with automerge on a green `check-results`.
- `minimumReleaseAgePackageManagerSync` makes npm resolve with `--before`, so transitive versions also serve the five-day `minimumReleaseAge`.
- Weekly Renovate updates run on Saturday only, so a dependency releasing on both weekend days gets one PR. Pre-commit hooks keep their monthly window.

Alternatives rejected:

| Alternative | Reason |
|---|---|
| Weekly Claude agent assessing each alert | Lock file maintenance fixes them deterministically, without API cost |
| `overrides` per vulnerable package | Manual upkeep; stale once the parent catches up |
| One-hour window at 01:00 | The hosted Renovate app does not guarantee a run within a given hour, so a one-hour window can skip a week |

## 📊 Consequences

- ✅ Transitive fixes land weekly without anyone touching the alerts.
- ✅ The five-day cooldown covers transitive versions too.
- ⚠️ A fix whose parent caps the version still needs a direct bump or an `overrides` entry by hand.
- ⚠️ Updates wait up to a week, security fixes included.
