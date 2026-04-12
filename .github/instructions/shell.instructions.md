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

## Pipes vs Process Substitution

Prefer process substitution over pipes when the exit code of the producing command matters:

```bash
# Bad — pipe masks gh failure
gh pr list --json number --jq '.[].number' | while read -r pr; do ...

# Good — gh failure propagates
while read -r pr; do ...
done < <(gh pr list --json number --jq '.[].number')
```

## Best Practices

- Quote variables: `"$var"` not `$var`.
- Use `[[ ]]` for conditionals, not `[ ]`.
- Use `$()` for command substitution, not backticks.
- Use `readonly` for constants.
- Prefer `printf` over `echo` for portable output.
- Use `trap` to clean up temporarily created resources on exit.
