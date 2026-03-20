# 🔄 Sync Copilot Instructions

## 📌 What

Downloads the canonical Copilot instruction set from [kellerlabs/homeracker](https://github.com/kellerlabs/homeracker)
and overwrites local copies.

Synced files:

- `.github/copilot-instructions.md` — repo-wide Copilot instructions
- `.github/instructions/*.instructions.md` — path-specific guidelines (markdown, openscad, python, renovate)
- `.github/pull_request_template.md` — PR template

## 🤔 Why

HomeRacker maintains a well-proven, optimized instruction set that ensures consistent AI behavior
across all repos. Instead of maintaining diverging copies, downstream repos can sync from the
single source of truth.

Current consumers:

- **homeracker-exclusive** — syncs daily via CI + manual trigger
- **homeracker-community** — planned

## 🔧 How

### One-liner (remote execution)

```bash
curl -fsSL https://raw.githubusercontent.com/kellerlabs/homeracker/main/.github/actions/sync-instructions/sync-instructions.sh | bash
```

Pass a ref to sync from a specific branch or tag:

```bash
curl -fsSL https://raw.githubusercontent.com/kellerlabs/homeracker/main/.github/actions/sync-instructions/sync-instructions.sh | bash -s -- sync-instructions-v1.0.0
```

### Reusable action

```yaml
- uses: kellerlabs/homeracker/.github/actions/sync-instructions@sync-instructions-v1.0.0
  with:
    ref: main  # optional, defaults to main
```

The action only downloads files — it does not commit. The caller workflow handles git operations.

### Example workflow

```yaml
name: Sync Copilot Instructions
on:
  schedule:
    - cron: '0 6 * * 1'  # weekly Monday 06:00 UTC
  workflow_dispatch:

permissions:
  contents: write

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: kellerlabs/homeracker/.github/actions/sync-instructions@sync-instructions-v1.0.0

      - name: Commit and push
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add -A
          if git diff --cached --quiet; then
            echo "No changes to commit"
          else
            git commit -m "ci(instructions): sync from homeracker"
            git push
          fi
```

### Versioning

The action is tagged following the `sync-instructions-v<major>.<minor>.<patch>` convention
(managed by release-please). Renovate picks up tag updates automatically.

## 📚 References

- [GitHub docs: Repository custom instructions](https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot)
- [VS Code docs: Custom instructions](https://code.visualstudio.com/docs/copilot/copilot-customization)
