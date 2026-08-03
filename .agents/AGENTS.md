# Git Commit Rules
- **NEVER** skip pre-commits (e.g. do not use `--no-verify`).
- If a pre-commit hook fails because an executable (like `flatten-validate`) is not found, it means the virtualenv is not initialized or `scadm` is not installed.
- When in doubt about failing hooks or missing environments, **ASK** the user for help rather than bypassing the safety checks.
