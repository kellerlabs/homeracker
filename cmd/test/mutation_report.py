#!/usr/bin/env python3
"""Mutation testing helpers for CI: scope a mutmut run to a PR and render its results.

Subcommands:
    scope           Print mutmut name globs for a package's functions changed since a base commit.
    report          Render one package's section of the markdown report (PR comment and job summary).
    gate            Fail when a mutant survives in a package's functions changed by the PR.
    combine         Join package sections into the PR comment.
    discord         Print a Discord webhook payload for a full run.
    coverage-badge  Convert coverage.py JSON into a shields.io endpoint badge.
"""

import argparse
import ast
import fnmatch
import json
import re
import subprocess
import sys
from pathlib import Path

MARKER = "<!-- mutation-report -->"
PACKAGES = ("scadm", "scadfmt")
MAX_LISTED_SURVIVORS = 25
_HUNK_RE = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")
_RESULT_RE = re.compile(r"^\s*(\S+): (.+)$")


def parse_changed_lines(diff: str) -> dict[str, set[int]]:
    """Collect the new-side line numbers touched by a unified diff.

    Args:
        diff: Output of ``git diff -U0``.

    Returns:
        Mapping of file path (relative to the repo root) to changed line numbers. A pure
        deletion marks the lines on both sides of the removed block.
    """
    changed: dict[str, set[int]] = {}
    current = None
    for line in diff.splitlines():
        if line.startswith("+++ "):
            path = line[4:]
            current = path[2:] if path.startswith("b/") else None
            continue
        match = _HUNK_RE.match(line)
        if match and current:
            start, count = int(match.group(1)), int(match.group(2) or 1)
            lines = range(start, start + count) if count else range(start, start + 2)
            changed.setdefault(current, set()).update(lines)
    return changed


def source_root(package: str) -> str:
    """Return the repo path of a package's project folder.

    Args:
        package: One of ``PACKAGES``.

    Returns:
        Path relative to the repo root, such as ``cmd/scadm``.
    """
    return f"cmd/{package}"


def module_name(path: str, package: str) -> str | None:
    """Map a repo path to the dotted module mutmut uses, or None if it isn't the package's source.

    Args:
        path: File path relative to the repo root.
        package: One of ``PACKAGES``.

    Returns:
        Dotted module name such as ``scadm.flatten``, or None.
    """
    root = source_root(package)
    if not path.startswith(f"{root}/{package}/") or not path.endswith(".py"):
        return None
    parts = path[len(root) + 1 : -3].split("/")
    if parts[-1] == "__init__":
        parts = parts[:-1]
    return ".".join(parts)


def _span(node: ast.AST) -> range:
    first = min([node.lineno] + [d.lineno for d in getattr(node, "decorator_list", [])])
    return range(first, node.end_lineno + 1)


def changed_functions(source: str, lines: set[int]) -> list[str]:
    """Name the top-level functions and methods that contain any of the given lines.

    Args:
        source: Python source of one module.
        lines: Changed line numbers in that module.

    Returns:
        mutmut function keys, ``x_<func>`` or ``xǁ<Class>ǁ<method>``, in source order.
    """
    keys = []
    for node in ast.parse(source).body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            if lines.intersection(_span(node)):
                keys.append(f"x_{node.name}")
        elif isinstance(node, ast.ClassDef):
            for item in node.body:
                if isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef)) and lines.intersection(_span(item)):
                    keys.append(f"xǁ{node.name}ǁ{item.name}")
    return keys


def scope(diff: str, repo_root: Path, package: str) -> list[str]:
    """Turn a diff into mutmut name globs for every changed function of a package.

    Args:
        diff: Output of ``git diff -U0 <base>...HEAD``.
        repo_root: Repository root, to read the changed files at HEAD.
        package: One of ``PACKAGES``.

    Returns:
        Globs such as ``scadm.flatten.x__parse_definitions__mutmut_*``.
    """
    globs = []
    for path, lines in sorted(parse_changed_lines(diff).items()):
        module = module_name(path, package)
        file = repo_root / path
        if module is None or not file.is_file():
            continue
        for key in changed_functions(file.read_text(encoding="utf-8"), lines):
            globs.append(f"{module}.{key}__mutmut_*")
    return globs


def parse_results(text: str) -> dict[str, str]:
    """Parse ``mutmut results --all true`` output.

    Args:
        text: Command output, one ``<name>: <status>`` per line.

    Returns:
        Mapping of mutant name to status.
    """
    results = {}
    for line in text.splitlines():
        match = _RESULT_RE.match(line)
        if match and "__mutmut_" in match.group(1):
            results[match.group(1)] = match.group(2).strip()
    return results


def summarize(results: dict[str, str], globs: list[str] | None) -> dict:
    """Count statuses of the mutants in scope.

    Args:
        results: Mapping of mutant name to status.
        globs: Name globs of the run, or None for a full run.

    Returns:
        Dict with ``killed``, ``survived``, ``timeout``, ``other``, ``total``, ``score`` and
        the sorted ``survivors`` names.
    """
    in_scope = {
        name: status
        for name, status in results.items()
        if globs is None or any(fnmatch.fnmatchcase(name, g) for g in globs)
    }
    counts = {"killed": 0, "survived": 0, "timeout": 0, "other": 0}
    for status in in_scope.values():
        counts[status if status in counts else "other"] += 1
    tested = counts["killed"] + counts["survived"] + counts["timeout"]
    score = (counts["killed"] + counts["timeout"]) / tested * 100 if tested else None
    survivors = sorted(n for n, s in in_scope.items() if s == "survived")
    return {**counts, "total": len(in_scope), "score": score, "survivors": survivors}


def render_report(summary: dict, *, package: str, functions: int | None, timed_out: bool, diffs: dict[str, str]) -> str:
    """Render one package's section of the markdown report.

    Args:
        summary: Output of ``summarize``.
        package: One of ``PACKAGES``.
        functions: Number of changed functions in scope, or None for a full run.
        timed_out: Whether the run hit its time limit.
        diffs: ``mutmut show`` output per listed survivor.

    Returns:
        Markdown starting with the package's heading.
    """
    scope_text = f"all `{package}` functions" if functions is None else f"{functions} changed function(s)"
    out = [f"### 🧰 {package}", ""]
    if functions == 0:
        out.append(f"No `{package}` functions changed in this PR, nothing to mutate.")
        return "\n".join(out) + "\n"
    score = "n/a" if summary["score"] is None else f"{summary['score']:.1f}%"
    out += [
        f"Scope: {scope_text}. Score: **{score}**",
        "",
        "| 🎉 Killed | 🙁 Survived | ⏰ Timeout | Not run | Total |",
        "|---|---|---|---|---|",
        "| " + " | ".join(str(summary[k]) for k in ("killed", "survived", "timeout", "other", "total")) + " |",
        "",
    ]
    if timed_out:
        out += [
            "> [!WARNING]",
            "> The run hit its 5 minute limit, so results are partial. If this keeps happening,"
            " consider moving per-PR mutation runs to a nightly job.",
            "",
        ]
    survivors = summary["survivors"]
    if not survivors:
        out.append("✅ No surviving mutants.")
        return "\n".join(out) + "\n"
    out += [
        "Each survivor is a change to the code that no test noticed. Add or tighten a test until it fails,"
        " or mark a true equivalent with `# pragma: no mutate`. Survivors in functions a PR changes fail its check.",
        "",
    ]
    for name in survivors[:MAX_LISTED_SURVIVORS]:
        body = diffs.get(name, "").strip() or "(diff unavailable)"
        out += [f"<details><summary><code>{name}</code></summary>", "", "```diff", body, "```", "</details>"]
    if len(survivors) > MAX_LISTED_SURVIVORS:
        out += [
            "",
            f"…and {len(survivors) - MAX_LISTED_SURVIVORS} more. Run `mutmut results` locally for the full list.",
        ]
    return "\n".join(out) + "\n"


def combine(sections: list[str]) -> str:
    """Join package sections into one PR comment.

    Args:
        sections: Outputs of ``render_report``, one per package.

    Returns:
        Markdown starting with the upsert marker.
    """
    return "\n".join([MARKER, "## 🧬 Mutation testing", "", *sections])


def discord_payload(summary: dict, run_url: str, package: str) -> dict:
    """Build the Discord webhook payload for a full run.

    Args:
        summary: Output of ``summarize`` for a full run.
        run_url: Link to the workflow run.
        package: One of ``PACKAGES``.

    Returns:
        Webhook JSON body with a single embed.
    """
    score = "n/a" if summary["score"] is None else f"{summary['score']:.1f}%"
    fields = [
        ("Score", score),
        ("🎉 Killed", summary["killed"]),
        ("🙁 Survived", summary["survived"]),
        ("⏰ Timeout", summary["timeout"]),
    ]
    return {
        "embeds": [
            {
                "title": f"🧬 Weekly mutation run: {package}",
                "url": run_url,
                "description": "Surviving mutants are listed in the run's job summary.",
                "fields": [{"name": n, "value": str(v), "inline": True} for n, v in fields],
            }
        ]
    }


def coverage_badge(coverage_json: dict) -> dict:
    """Build a shields.io endpoint badge from coverage.py JSON output.

    Args:
        coverage_json: Parsed ``coverage json`` output.

    Returns:
        Endpoint badge JSON.
    """
    percent = coverage_json["totals"]["percent_covered"]
    color = "brightgreen" if percent >= 90 else "green" if percent >= 80 else "yellow" if percent >= 70 else "red"
    return {"schemaVersion": 1, "label": "coverage", "message": f"{percent:.0f}%", "color": color}


def _mutmut(*args: str, cwd: Path) -> str:
    return subprocess.run(
        ["mutmut", *args], cwd=cwd, capture_output=True, text=True, encoding="utf-8", check=True
    ).stdout


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    pkg = argparse.ArgumentParser(add_help=False)
    pkg.add_argument("--package", required=True, choices=PACKAGES)
    p_scope = sub.add_parser("scope", parents=[pkg])
    p_scope.add_argument("--base", required=True, help="Base commit of the PR")
    p_report = sub.add_parser("report", parents=[pkg])
    p_report.add_argument("--globs-file", type=Path, help="Scope file from `scope`; omit for a full run")
    p_report.add_argument("--timed-out", action="store_true")
    p_gate = sub.add_parser("gate", parents=[pkg])
    p_gate.add_argument("--globs-file", type=Path, required=True, help="Scope file from `scope`")
    p_discord = sub.add_parser("discord", parents=[pkg])
    p_discord.add_argument("--run-url", required=True)
    p_combine = sub.add_parser("combine")
    p_combine.add_argument("sections", nargs="+", type=Path, help="Section files from `report`")
    p_cov = sub.add_parser("coverage-badge")
    p_cov.add_argument("coverage_json", type=Path)
    return parser


def _summary(globs_file: Path | None, package_dir: Path) -> tuple[dict, list[str] | None]:
    """Summarize a mutmut run, scoped to the globs in globs_file if given."""
    globs = None
    if globs_file:
        globs = [g for g in globs_file.read_text(encoding="utf-8").splitlines() if g.strip()]
    # An empty scope means mutmut never ran, so there are no results to read.
    results = {} if globs == [] else parse_results(_mutmut("results", "--all", "true", cwd=package_dir))
    return summarize(results, globs), globs


def _gate(args: argparse.Namespace, package_dir: Path) -> int:
    """Fail on survivors in the changed functions, even when the run mutated the whole package."""
    survivors = _summary(args.globs_file, package_dir)[0]["survivors"]
    for name in survivors:
        print(f"::error title=Surviving mutant ({args.package})::{name}")
    return 1 if survivors else 0


def _results(args: argparse.Namespace, package_dir: Path) -> None:
    """Print the report or Discord payload of a mutmut run."""
    summary, globs = _summary(getattr(args, "globs_file", None), package_dir)
    if args.command == "discord":
        print(json.dumps(discord_payload(summary, args.run_url, args.package)))
        return
    listed = summary["survivors"][:MAX_LISTED_SURVIVORS]
    diffs = {name: _mutmut("show", name, cwd=package_dir) for name in listed}
    functions = None if globs is None else len(globs)
    report = render_report(summary, package=args.package, functions=functions, timed_out=args.timed_out, diffs=diffs)
    print(report, end="")


def main(argv: list[str] | None = None) -> int:
    """CLI entry point.

    Args:
        argv: Arguments without the program name (defaults to ``sys.argv[1:]``).

    Returns:
        Process exit code.
    """
    args = _build_parser().parse_args(argv)
    repo_root = Path(__file__).resolve().parents[2]
    if args.command == "coverage-badge":
        print(json.dumps(coverage_badge(json.loads(args.coverage_json.read_text(encoding="utf-8")))))
    elif args.command == "combine":
        print(combine([f.read_text(encoding="utf-8") for f in args.sections]), end="")
    elif args.command == "scope":
        root = source_root(args.package)
        diff = subprocess.run(
            ["git", "diff", "-U0", f"{args.base}...HEAD", "--", f"{root}/{args.package}"],
            cwd=repo_root,
            capture_output=True,
            text=True,
            encoding="utf-8",
            check=True,
        ).stdout
        print("\n".join(scope(diff, repo_root, args.package)))
    elif args.command == "gate":
        return _gate(args, repo_root / source_root(args.package))
    else:
        _results(args, repo_root / source_root(args.package))
    return 0


if __name__ == "__main__":
    sys.exit(main())
