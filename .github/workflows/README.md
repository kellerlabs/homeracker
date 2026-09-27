# GitHub Workflows

This directory contains automated workflows for the HomeRacker repository.

## Workflows

### 1. Handle Release PRs (`release-please.yml`)
Creates and updates release PRs based on conventional commits. The release PR accumulates all changes until it gets merged.

**Triggers:** Push to `main` branch

**Requirements:** GitHub App credentials

### 2. Automerge Release PRs (`automerge-release.yml`)
Automatically merges release PRs on a schedule. This is what triggers the release PR to be merged and creates the actual release.

**Triggers:**
- Weekly schedule
- Manual workflow dispatch

**Requirements:** GitHub App credentials

### 3. Validate PR Title (`validate-pr-title.yml`)
Validates PR titles against Conventional Commits format to prevent broken releases when using "Squash & Merge".

**Triggers:** PR opened, edited, synchronize, or reopened

**Requirements:** None (uses default `github.token`)

### 4. Mutation Tests (`mutation-tests.yml`)
Runs `mutmut` on `scadm`. On PRs it mutates only the changed functions and edits one PR comment with the survivors. The weekly run covers the whole codebase, posts its stats to Discord and publishes the mutation badge. See [TESTING.md](../../TESTING.md#mutation-testing).

**Triggers:**
- PRs touching `cmd/scadm/scadm/**` or the run setup (release-please PRs skip it)
- Weekly schedule (Monday 03:00 UTC)
- Manual workflow dispatch

**Requirements:** `DISCORD_CI_WEBHOOK_URL` secret (the Discord post is skipped with a warning without it), `contents: write` to push the `badges` branch

### 5. Coverage Badge (`coverage-badge.yml`)
Measures `scadm` unit test coverage on `main` and publishes the README badge to the `badges` branch. The coverage gate itself runs in the `scadm-tests` pre-commit hook.

**Triggers:** Push to `main` touching `cmd/scadm/**` or the badge tooling, manual workflow dispatch

**Requirements:** `contents: write` to push the `badges` branch

## GitHub App Setup

The release and automerge workflows require a GitHub App with the following permissions:
- Contents: Read & Write
- Pull Requests: Read & Write

### Required Repository Secrets

Configure these secrets in your repository settings:

1. `RELEASES_APP_ID` - The GitHub App ID
2. `RELEASES_APP_PRIVATE_KEY` - The GitHub App private key

### Why a GitHub App?

A GitHub App is required to allow subsequent workflow runs to be triggered by the release workflows. The default `GITHUB_TOKEN` has limitations that prevent workflow-triggered events from starting new workflows.

## References

- [Camunda Infrastructure Actions](https://github.com/camunda/infra-global-github-actions/tree/main/teams/infra/pull-request)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Release Please](https://github.com/googleapis/release-please)
