# 📋 Let an Agent Adapt scadfmt to New OpenSCAD Nightlies

## 📌 Status

**Accepted**: 2026-09-28

## 🤔 Context

- Renovate bumps the pinned OpenSCAD nightly once a week (Saturday) and automerges on a green [`check-results`](gate-prs-with-a-single-check-results-job.md).
- New syntax in a nightly can break [scadfmt](build-own-openscad-formatter-scadfmt.md). The canary and unit tests only cover syntax scadfmt already knows; spotting new syntax means reading upstream changes.
- The goal is close to zero manual toil without unreviewed code reaching `main`.

## 🔧 Decision

On the Renovate OpenSCAD PR, [`scadfmt-agent.yml`](../../.github/workflows/scadfmt-agent.yml) lets a Claude agent adapt scadfmt, and a person approves the result.

- **Gate:** runs only for a PR from this repo by `renovate[bot]` on `renovate/openscad-nightly`. [`grammar-diff.sh`](../../cmd/scadfmt/nightly/grammar-diff.sh) diffs `src/core/lexer.l` and `src/core/parser.y` from the start of the old nightly's date to the end of the new one's (UTC). A nightly carries only its build date, so a commit from either day may be diffed twice but is never missed. The agent is skipped when the diff is empty or the branch already carries an agent commit.
- **Runtime:** [claude-code-action](https://github.com/anthropics/claude-code-action) with `CLAUDE_CODE_OAUTH_TOKEN` (subscription), `allowed_bots: renovate`, `claude-sonnet-5`, 60 turns (the first full probe took 40), 30 minutes.
- **Instructions:** the [`scadfmt-adapt`](../../.claude/skills/scadfmt-adapt/SKILL.md) skill, which people also use when taking over.
- **Sources:** OpenSCAD's `src/core/` and `tests/data/scad/`, checked out by the gate script, and BOSL2 from `scadm install`, both local. `WebFetch` for `openscad.org` only.
- **Isolation:** the agent job has `contents: read` only and passes its read-only token to the action. Tools are file tools and a Bash allowlist (`check.sh`, `pytest`, `scadfmt format`, OpenSCAD, `git diff`/`status`). No push, no `gh`, no WebSearch. Subprocesses run without the OAuth and GitHub tokens (`CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`).
- **Verify:** a job without any token applies the agent's patch and rejects it unless it only changes formatter sources, the two canary files and new test files ([`check-patch.sh`](../../cmd/scadfmt/nightly/check-patch.sh)). Existing tests, `check.sh` and the coverage config stay as reviewed, so the patch cannot weaken its own checks. The existing tests run on their own, then all tests with the coverage gate, then the canary.
- **Publish:** a separate job never runs the agent's code. It applies the verified patch again, commits as `scadfmt-agent` with git hooks off and pushes with the token of a dedicated agent GitHub App (Contents write only, separate from the releases app), so CI runs on the commit.
- **E2E probe:** the `scadfmt-e2e` label runs the flow on any PR. It fakes an older nightly pin, breaks scadfmt for a construct from that grammar diff, and pushes the agent's fix to a throwaway branch. See the [CI overview](../../.github/workflows/README.md#-e2e-probe).
- **Review:** on a branch with an agent commit, the `human-review` job targets the `scadfmt-review` environment, which requires a reviewer. `check-results` waits for the approval. Renovate ignores the agent's commits (`gitIgnoredAuthors`), so it automerges once approved.

| Outcome | Result |
|---|---|
| Grammar unchanged | Agent skipped, automerge as usual |
| No change needed | PR comment with the reason, automerge |
| Adapted, tests green | Push, summary comment, waits for approval |
| Agent failed or tests red | No push, result as artifact, comment asks a person to take over; `check-results` stays red |

### Alternatives Considered

| Approach | Verdict | Reason |
|---|---|---|
| Agent on every nightly PR | ❌ Rejected | 52 runs a year, most with nothing to do |
| Agent opens its own PR | ❌ Rejected | Bump and adaptation would land separately |
| Agent pushes or comments itself | ❌ Rejected | Puts a write credential next to fetched content |
| Open web access | ❌ Rejected | `WebFetch` rules are per domain, so GitHub cannot be narrowed to trusted repos; prompt injection could exfiltrate the token |
| Failing status plus manual merge | ❌ Rejected | The environment approval is one click and keeps automerge |

## 📊 Consequences

- **Positive**: weekly toil is one approval click, only in weeks where the grammar changed.
- **Positive**: bump and adaptation land as one reviewed change.
- **Negative**: uses subscription quota; `CLAUDE_CODE_OAUTH_TOKEN` needs renewing when it expires.
- **Negative**: the gate misses syntax changes outside `lexer.l` and `parser.y`; the canary still catches regressions in known syntax.
- **Negative**: without the `scadfmt-review` environment and its required reviewer, `human-review` passes on its own. The environment is part of the setup in the [CI overview](../../.github/workflows/README.md#-scadfmt-agent-setup).
