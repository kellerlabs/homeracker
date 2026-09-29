# 📋 Gate scadm on coverage and fail PRs on surviving mutants in the functions they change

## 📌 Status

**Accepted**: 2026-09-29

## 🤔 Context

- Supersedes [gate-scadm-coverage-and-mutation-test-changed-functions.md](https://github.com/kellerlabs/homeracker/blob/acc4c44a2d83e3706173e9b2b218527b5b5ff7e4/docs/decisions/gate-scadm-coverage-and-mutation-test-changed-functions.md).
- More and more of `scadm` and `scadfmt` is written with AI help. Passing tests alone don't show whether those tests would catch a regression.
- Coverage measures how much code the tests run. Mutation testing measures whether the tests notice when that code changes. Neither is enough alone.
- A whole-codebase mutation score says nothing about a single PR and is hard to act on. Surviving mutants in code the author just changed are specific and fixable ([Practical Mutation Testing at Scale: A view from Google](https://homes.cs.washington.edu/~rjust/publ/practical_mutation_testing_tse_2021.pdf)).
- A report-only PR comment is easy to merge past, so survivors lower the badge score without anyone deciding to accept them.
- Many raw mutants are unproductive: log text, argparse help, exception messages. No test should pin those.

## 🔧 Decision

**Coverage: `pytest-cov` in the `scadm-tests` pre-commit hook.**

- The hook runs pytest with `--cov` and branch coverage. `fail_under = 90` in [`cmd/scadm/pyproject.toml`](../../cmd/scadm/pyproject.toml) is the gate. CI runs every hook on all files, so every PR hits it.
- Ratchet by hand: raise `fail_under` when coverage grows well past it. Never lower it.
- The hook sets `PYTHONWARNDEFAULTENCODING=1` and pytest turns `EncodingWarning` into an error, so text I/O without an explicit encoding fails on every OS, not only on Windows.
- Alternatives rejected:
  - Codecov or Coveralls: an external service for a number coverage.py already computes.
  - A separate coverage workflow: runs the same unit tests a second time on every PR.
  - An automatic ratchet written to a tracked file: CI can't commit it back, and locally it dirties the tree on every run.

**Mutation testing: `mutmut`, failing on survivors in changed functions.**

- 🧬 Per PR ([`mutation-tests.yml`](../../.github/workflows/mutation-tests.yml)): [`cmd/test/mutation_report.py`](../../cmd/test/mutation_report.py) maps the diff to changed top-level functions and methods, and only those get mutated. Changes to the run setup (workflow, mutmut config, pinned versions, report script) mutate the whole codebase instead. Release-please PRs are skipped: they only bump versions and changelogs.
- 🚦 Any mutant surviving in a changed function fails the job, and with it `check-results`. On a full run only the changed functions count, so older survivors elsewhere never block a PR. A true equivalent gets `# pragma: no mutate` on the statement's first line.
- ⏱️ The per-PR run stops after 5 minutes (`timeout 300`), warns, and suggests moving the run to a nightly job. The gate judges whatever results were collected.
- 💬 Results land in one PR comment that each run edits in place, posted before the gate runs. Fork PRs get a read-only token, so they only get the job summary.
- 📅 Weekly (Monday 03:00 UTC) and on dispatch: a full run posts its stats to Discord `#homeracker-ci` through the `DISCORD_CI_WEBHOOK_URL` secret and publishes the mutation badge. Survivors go to the job summary.
- 🏷️ Coverage and mutation badges are shields.io endpoint JSON on the `badges` branch, written on pushes to `main` and by the weekly run.
- 🔇 `do_not_mutate_patterns` skips log calls, argparse `help`/`description`/`metavar`/`prog` lines and `raise X(...)` messages. argparse calls keep one keyword per line, so flag names, `dest` and `choices` stay mutated.
- Alternatives rejected:
  - Report only: survivors get merged unnoticed and the score drifts down.
  - Failing only on survivors new since the base commit: needs a second mutmut run on the base, and mutant numbers shift when a function changes, so matching them is guesswork.
  - Failing when a full per-PR run scores below the badge: runtime grows with the codebase, and most survivors have nothing to do with the PR.
  - `# pragma: no mutate` on every log or help line: dozens of annotations where three patterns do the job.
  - cosmic-ray (session database, separate config) and mutpy (unmaintained).
  - A gist-hosted badge: needs a personal access token as a secret.

## 📊 Consequences

- ✅ A PR can't lower the mutation score of the code it touches, and the author sees each survivor in the PR comment.
- ✅ The weekly Discord report keeps overall test debt visible without adding noise to PRs.
- ❌ Touching a `scadm` function that already has a survivor means killing it in the same PR.
- ❌ Equivalent mutants (`encoding="UTF-8"`, the default `open` mode, `None` for `False`) need a pragma, which also skips every other mutant on that line.
- ❌ A timed-out run can miss a survivor, and mutmut has no native Windows support (use WSL).
- ❌ The badge jobs need `contents: write` to push the `badges` branch.
