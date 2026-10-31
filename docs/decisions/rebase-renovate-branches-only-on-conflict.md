# 📋 Rebase Renovate branches only on conflict

## 📌 Status

**Accepted**: 2026-10-31

## 🤔 Context

- `main` required branches to be up to date before merging, so Renovate (`rebaseWhen: auto`) rebased every automerge PR whenever `main` moved.
- The [scadfmt agent](agent-adapts-scadfmt-to-openscad-nightly.md) commits onto the OpenSCAD nightly PR. Its commits are in `gitIgnoredAuthors` so Renovate still automerges the PR, and that also lets Renovate rebuild the branch. Each merge to `main` dropped the agent's commit, ran the agent again and reset the approval.
- PRs are squash-merged, so a branch behind `main` merges cleanly as long as it has no conflict.

## 🔧 Decision

- `renovate.json5` sets `"rebaseWhen": "conflicted"` for all Renovate PRs.
- The `main` ruleset no longer requires branches to be up to date before merging. Required checks stay `check-results` and `validate-title`.
- Alternatives:
  - `conflicted` with up to date branches still required: ❌ every Renovate PR behind `main` blocks forever.
  - `conflicted` only for the nightly PR: ❌ needs the up to date requirement off anyway, and the other Renovate PRs gain nothing from rebasing.
  - Drop `gitIgnoredAuthors` and merge from the workflow after approval: ❌ adds merge logic to the agent workflow.
  - GitHub merge queue: ❌ tests against the latest `main`, but adds a queue to a repo with few concurrent PRs.

## 📊 Consequences

- The agent's commit survives merges to `main`, so it runs once per nightly and is approved once.
- Fewer CI runs and less Renovate churn on every PR.
- A green check may have run against an older `main`. Two PRs that each pass alone can break `main` together. The PR checks are path-filtered and do not run on `main`, so a break shows only once a later PR runs the affected check.
- Human PRs no longer need "Update branch" before merging, with the same risk.
