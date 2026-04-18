# 📋 ADR-002: Code Coverage and Mutation Testing

## 📌 Status

**Accepted** — 2026-04-18

## 🤔 Context

With AI-assisted development increasing across HomeRacker, we need deterministic guardrails to maintain code quality. Two complementary metrics address this:

- **Code coverage** (quantity): measures how much code is exercised by tests
- **Mutation testing** (quality): measures how well tests detect code changes

Neither metric alone is sufficient — high coverage with weak assertions gives a false sense of security, while mutation testing without baseline coverage is impractical.

### Tools Evaluated

| Tool | Category | Verdict | Reason |
|---|---|---|---|
| **pytest-cov** | Coverage | ✅ Selected | De-facto standard for pytest, wraps coverage.py, well-maintained, 7.1.0 |
| coverage.py (direct) | Coverage | ❌ | pytest-cov provides better integration and CLI ergonomics |
| Codecov / Coveralls | Coverage SaaS | ❌ | External dependency; local-first approach preferred |
| **mutmut** | Mutation | ✅ Selected | Python-native, pytest runner, incremental runs, 3.5.0 |
| cosmic-ray | Mutation | ❌ | More complex setup, less active maintenance |
| mutpy | Mutation | ❌ | Unmaintained since 2020 |

## 🔧 Decision

### Coverage

- **Tool**: `pytest-cov==7.1.0` (pinned, Renovate-managed)
- **Minimum threshold**: 80% (branch coverage enabled)
- **Ratchet mechanism**: `cmd/scadm/.coverage-threshold` stores the actual coverage percentage — subsequent runs must meet or exceed this value, ensuring coverage only increases
- **Wrapper script**: `cmd/test/test-coverage.sh` runs locally and in CI
- **CI workflow**: `.github/workflows/coverage.yml` triggers on PRs and main pushes (scoped to `cmd/scadm/**` paths)

### Mutation Testing

- **Tool**: `mutmut==3.5.0` (pinned, Renovate-managed)
- **Schedule**: Weekly cron (Monday 03:00 UTC) + manual dispatch — mutation testing is CPU-intensive and not suitable for every PR
- **Wrapper script**: `cmd/test/test-mutmut.sh` runs locally and in CI
- **CI workflow**: `.github/workflows/mutation-tests.yml`

### Configuration

Both tools are configured in `cmd/scadm/pyproject.toml`:
- `[tool.coverage.run]` — source paths, branch coverage
- `[tool.coverage.report]` — exclusion patterns
- `[tool.mutmut]` — paths to mutate, test directory

## 📊 Consequences

- **Positive**: Deterministic quality gate — CI fails on coverage regression
- **Positive**: Ratchet prevents "coverage creep" downward over time
- **Positive**: Mutation tests catch weak assertions and low-quality tests
- **Positive**: Both tools run locally for fast developer feedback
- **Negative**: Mutation testing is slow (minutes), hence weekly schedule
- **Negative**: Initial 80% threshold may require test backfill before CI passes

## 📚 References

- [pytest-cov documentation](https://pytest-cov.readthedocs.io/)
- [coverage.py documentation](https://coverage.readthedocs.io/)
- [mutmut documentation](https://mutmut.readthedocs.io/)
- [GitHub Issue #327](https://github.com/kellerlabs/homeracker/issues/327)
- [ADR-001: Image Hosting](ADR-001-image-hosting-assets-repo.md)
