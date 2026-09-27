# 📋 Gate scadm on coverage and mutation-test it weekly

## 📌 Status

**Accepted**: 2026-09-27

## 🤔 Context

- More and more of `scadm` is written with AI help. Passing tests alone don't show whether those tests exercise the code or would catch a regression.
- Code coverage measures how much code the tests run. Mutation testing measures whether the tests notice when that code changes. High coverage with weak assertions passes one check and fails the other, so neither is enough alone.
- Unit tests already run in the `scadm-tests` pre-commit hook: locally when a commit touches `cmd/scadm/`, and on every PR in the [Pre-commit workflow](../../.github/workflows/pre-commit.yml), which runs all hooks on all files.

## 🔧 Decision

**Coverage: `pytest-cov`, enforced by the existing `scadm-tests` hook.**

- The hook runs pytest with `--cov`. Branch coverage is on.
- `fail_under = 90` in `[tool.coverage.report]` of [`cmd/scadm/pyproject.toml`](../../cmd/scadm/pyproject.toml) is the gate.
- Ratchet by hand: when coverage grows well past the gate, raise `fail_under` in the same PR. Never lower it.
- Alternatives rejected:
  - Codecov or Coveralls: an external service for a number coverage.py already computes locally.
  - A separate coverage workflow plus a wrapper script: runs the same unit tests a second time on every PR.
  - An automatic ratchet that writes the measured value to a tracked file after each run: CI can't commit the file back, so the ratchet never moves there. Locally it dirties the tree on every run, and any change that removes well-tested lines fails the build by a fraction of a percent.

**Mutation testing: `mutmut`, weekly and report-only.**

- [`mutation-tests.yml`](../../.github/workflows/mutation-tests.yml) runs Mondays at 03:00 UTC, on manual dispatch, and on PRs that change its workflow, the mutmut config or pinned versions. It writes the killed and surviving counts to the job summary and never fails on survivors.
- Config lives in `[tool.mutmut]` of `cmd/scadm/pyproject.toml`. It mutates `scadm/` only and runs the unit tests, not the integration ones.
- Alternatives rejected:
  - cosmic-ray: needs a session database and a separate config file.
  - mutpy: unmaintained.
  - Mutation testing on every PR: a full run takes minutes and runs every mutant, including ones a PR didn't touch.
  - Failing on a mutation score: too many survivors today to make that a useful signal.

## 📊 Consequences

- ✅ A commit that drops `scadm` coverage below the gate fails the hook contributors already run, with no extra CI job.
- ✅ Surviving mutants point at specific weak assertions, and nothing needs a service account.
- ❌ The hook needs `pytest-cov` from `requirements.txt`, and the ratchet is manual, so the gate can lag real coverage.
- ❌ mutmut has no native Windows support (use WSL), and survivors block nothing until someone reads the weekly report.
