---
applyTo: "**/*.sh,**/*.yml,**/*.yaml"
---

# Shell Guidelines

## Strict Mode

Always start shell scripts and GitHub Actions `run:` blocks with:

```bash
set -euo pipefail
```

- `set -e`: Exit on error.
- `set -u`: Treat unset variables as errors.
- `set -o pipefail`: Fail on first error in a pipeline.

## Error-Safe Iteration

Capture command output before iterating so failures are caught by `set -e`:

```bash
# Bad — pipe masks command failure
gh pr list --json number --jq '.[].number' | while read -r pr; do ...

# Bad — process substitution does not reliably trip set -e
while read -r pr; do ...
done < <(gh pr list --json number --jq '.[].number')

# Good — command failure is caught before iterating
prs="$(gh pr list --json number --jq '.[].number')"
[[ -z "$prs" ]] && exit 0
while read -r pr; do ...
done <<< "$prs"
```

## Best Practices

- Quote variables: `"$var"` not `$var`.
- Use `[[ ]]` for conditionals, not `[ ]`.
- Use `$()` for command substitution, not backticks.
- Use `readonly` for constants.
- Prefer `printf` over `echo` for portable output.
- Use `trap` to clean up temporarily created resources on exit.
