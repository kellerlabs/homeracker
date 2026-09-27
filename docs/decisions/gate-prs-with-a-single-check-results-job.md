# 📋 Gate PRs with a Single check-results Job

## 📌 Status

**Accepted**, 2026-09-27

## 🤔 Context

- Eight workflows run on `pull_request`, each as its own file with its own `paths:` filter.
- A path-filtered workflow cannot be a required check: when it does not run, the PR waits forever for it. So `integration-tests`, `mutation-tests`, `test-setup-openscad`, `validate-models` and `web` guard nothing at merge time.
- Renovate automerges on green checks, so an unrequired failing check only blocks it by luck of timing.
- The planned scadfmt agent flow ([#177](https://github.com/kellerlabs/homeracker/issues/177)) will need a human approval step that blocks the merge.

## 🔧 Decision

One PR workflow, `ci.yml`, modeled on [camunda/camunda](https://github.com/camunda/camunda/blob/main/.github/workflows/ci.yml):

- **`detect-changes`** computes path filters once and exposes one output per area.
- **Every PR job** is an existing workflow switched to `workflow_call`, called from `ci.yml` behind an `if:` on its filter.
- **`check-results`** runs with `if: always()`, needs every job, and fails on any `failure` or `cancelled`. `skipped` counts as success.
- **Branch protection** on `main` requires `check-results` only.

### Alternatives Considered

| Approach | Verdict | Reason |
|---|---|---|
| Require each workflow directly | ❌ Rejected | Path-filtered workflows block PRs they skip |
| Drop path filters, run everything always | ❌ Rejected | Slow PRs, wasted runner minutes on OpenSCAD renders and E2E |
| Third-party "wait for all checks" action | ❌ Rejected | Polls the checks API, extra dependency, races with late-starting workflows |

## 📊 Consequences

- **Positive**: every PR job is required when it applies, including path-filtered ones.
- **Positive**: a job that needs a person (an environment with required reviewers) blocks the merge through `check-results`.
- **Negative**: a new job must be added to both the `detect-changes` filter and the `check-results` `needs:`; missing the latter silently makes it optional. See the [CI overview](../../.github/workflows/README.md).
- **Negative**: renaming `check-results` breaks branch protection until the rule is updated.
