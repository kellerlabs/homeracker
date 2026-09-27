# 📋 Gate scadm on coverage and mutation-test the functions each PR changes

## 📌 Status

**Accepted**: 2026-09-27

## 🤔 Context

- Supersedes [gate-scadm-coverage-and-mutation-test-weekly.md](https://github.com/kellerlabs/homeracker/blob/060015180e8fdbf82a5844b68e21862c0e939546/docs/decisions/gate-scadm-coverage-and-mutation-test-weekly.md).
- More and more of `scadm` is written with AI help. Passing tests alone don't show whether those tests would catch a regression.
- Coverage measures how much code the tests run. Mutation testing measures whether the tests notice when that code changes. Neither is enough alone.
- A whole-codebase mutation score says nothing about a single PR and is hard to act on. Surviving mutants in code the author just changed are specific and fixable ([Practical Mutation Testing at Scale: A view from Google](https://homes.cs.washington.edu/~rjust/publ/practical_mutation_testing_tse_2021.pdf)).
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

**Mutation testing: `mutmut`, report-only.**

- 🧬 Per PR ([`mutation-tests.yml`](../../.github/workflows/mutation-tests.yml)): [`cmd/test/mutation_report.py`](../../cmd/test/mutation_report.py) maps the diff to changed top-level functions and methods, and only those get mutated. Changes to the run setup (workflow, mutmut config, pinned versions, report script) mutate the whole codebase instead. Release-please PRs are skipped: they only bump versions and changelogs. They still run the integration tests, the last check before a PyPI version that can't be re-uploaded.
- ⏱️ The per-PR run stops after 5 minutes (`timeout 300`), warns, and suggests moving the run to a nightly job.
- 💬 Results land in one PR comment that each run edits in place. Fork PRs get a read-only token, so they only get the job summary.
- 📅 Weekly (Monday 03:00 UTC) and on dispatch: a full run posts its stats to Discord `#homeracker-ci` through the `DISCORD_CI_WEBHOOK_URL` secret and publishes the mutation badge. Survivors go to the job summary.
- 🏷️ Coverage and mutation badges are shields.io endpoint JSON on the `badges` branch, written on pushes to `main` and by the weekly run.
- 🔇 `do_not_mutate_patterns` skips log calls, argparse `help`/`description`/`metavar`/`prog` lines and `raise X(...)` messages. argparse calls keep one keyword per line, so flag names, `dest` and `choices` stay mutated.
- Alternatives rejected:
  - A full run on every PR: most survivors have nothing to do with the PR, and runtime grows with the codebase.
  - Failing on a mutation score: a score is hard to act on, and some equivalent mutants can't be killed.
  - `# pragma: no mutate` on every log or help line: dozens of annotations where three patterns do the job.
  - cosmic-ray (session database, separate config) and mutpy (unmaintained).
  - A gist-hosted badge: needs a personal access token as a secret.

## 📊 Consequences

- ✅ PR authors see survivors only in the functions they changed, usually within seconds.
- ✅ The weekly Discord report keeps overall test debt visible without adding noise to PRs.
- ❌ A pattern-matched line skips every mutant on it, including the exception type in `raise ValueError(...)`.
- ❌ A few equivalent mutants remain (`encoding="UTF-8"`, the default `open` mode, `None` for `False`) and show up whenever their function changes.
- ❌ The badge jobs need `contents: write` to push the `badges` branch, and mutmut has no native Windows support (use WSL).
